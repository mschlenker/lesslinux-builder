#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
require "rexml/document"
require 'fileutils'
require 'MfsTranslator'
require 'digest/sha1'
require 'sqlite3' 

$lastpulse = Time.now.to_f 
$histfiles = 0

def traverse_dir(startdir, basedir, pgbar, tgtdir)
	now = Time.now.to_f 
	if now > $lastpulse + 0.3
		pgbar.pulse
		$lastpulse = now
	end
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	Dir.entries(startdir).each { |e|
		# puts "Parsing #{startdir}/#{e}"
		if e == "." || e == ".."
			# puts "Ignore directory #{e}"
		elsif File.symlink? "#{startdir}/#{e}"
			puts "Ignore symlink #{e}"
		elsif File.directory? "#{startdir}/#{e}" 
			traverse_dir("#{startdir}/#{e}", basedir, pgbar, tgtdir) 
		elsif File.file? "#{startdir}/#{e}"
			extract_file("#{startdir}/#{e}", basedir, pgbar, tgtdir) 
		end
	}
end

def extract_file(filepath, basedir, pgbar, tgtdir)
	if filepath =~  /index\.dat$/
		entries_found = false
		analyzed = IO.popen( ["msiecfinfo", filepath ]).readlines
		analyzed.each { |line|
			if line.strip =~ /Number/ && line.split(":")[1].strip.to_i > 0
				entries_found = true
			end
		}
		if entries_found == true
			shasum = Digest::SHA1.hexdigest File.new(filepath).read 
			lines = IO.popen( ["msiecfexport", filepath ]).readlines
			outname = tgtdir + "/IE_history_" + shasum + ".txt"
			outfile = File.new(outname, "w")
			lines.each { |l| outfile.write(l) }
			outfile.close
			idxfile = File.new(tgtdir + "/history_index.csv", "a")
			idxfile.write("\"#{filepath}\";\"#{outname}\";\n")
			idxfile.close 
			$histfiles += 1
			pgbar.text = "Gefunden: #{$histfiles} Dateien"
		end
	elsif filepath =~  /places\.sqlite$/
		# moz_places (   id INTEGER PRIMARY KEY, url LONGVARCHAR, title LONGVARCHAR, rev_host LONGVARCHAR, visit_count INTEGER DEFAULT 0, hidden INTEGER DEFAULT 0 NOT NULL, typed INTEGER DEFAULT 0 NOT NULL, favicon_id INTEGER, frecency INTEGER DEFAULT -1 NOT NULL, last_visit_date INTEGER , guid TEXT, foreign_count INTEGER DEFAULT 0 NOT NULL);
		shasum = Digest::SHA1.hexdigest File.new(filepath).read 
		outname = tgtdir + "/FF_history_" + shasum + ".csv"
		begin
			sqlite = SQLite3::Database.new(filepath)
			resset = sqlite.query("SELECT url, title, visit_count, last_visit_date FROM moz_places")
			outfile = File.new(outname, "w")
			outfile.write("\"URL\";\"Titel\";\"Zahl der Besuche\";\"Letzter Besuch\";\n") 
			resset.each { |e|
				outfile.write("\"#{e[0]}\";\"#{e[1]}\";#{e[2].to_s};#{e[3]};\n")
			}
			outfile.close 
			$histfiles += 1
			pgbar.text = "Gefunden: #{$histfiles} Dateien"
		rescue
		end
		idxfile = File.new(tgtdir + "/history_index.csv", "a")
		idxfile.write("\"#{filepath}\";\"#{outname}\";\n")
		idxfile.close 
		begin
			sqlite.close
		rescue
		end
	elsif filepath =~ /\/History$/ 
		# urls(id INTEGER PRIMARY KEY,url LONGVARCHAR,title LONGVARCHAR,visit_count INTEGER DEFAULT 0 NOT NULL,typed_count INTEGER DEFAULT 0 NOT NULL,last_visit_time INTEGER NOT NULL,hidden INTEGER DEFAULT 0 NOT NULL,favicon_id INTEGER DEFAULT 0 NOT NULL);
		shasum = Digest::SHA1.hexdigest File.new(filepath).read 
		outname = tgtdir + "/Chrome_history_" + shasum + ".csv"
		begin
			sqlite = SQLite3::Database.new(filepath)
			resset = sqlite.query("SELECT url, title, visit_count, last_visit_time FROM urls")
			outfile = File.new(outname, "w")
			outfile.write("\"URL\";\"Titel\";\"Zahl der Besuche\";\"Letzter Besuch\";\n") 
			resset.each { |e|
				outfile.write("\"#{e[0]}\";\"#{e[1]}\";#{e[2].to_s};#{e[3]};\n")
			}
			outfile.close 
			$histfiles += 1
			pgbar.text = "Gefunden: #{$histfiles} Dateien"
		rescue
		end
		idxfile = File.new(tgtdir + "/history_index.csv", "a")
		idxfile.write("\"#{filepath}\";\"#{outname}\";\n")
		idxfile.close 
		begin
			sqlite.close
		rescue
		end
	end
end

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
tlfile = "history-extractor.xml"
tl = MfsTranslator.new(lang, tlfile)
@tl = tl

lvb = Gtk::VBox.new
window = Gtk::Window.new
window.signal_connect("delete_event") {
        puts "delete event occurred"
        false
}

window.signal_connect("destroy") {
        puts "destroy event occurred"
        Gtk.main_quit
}

explainframe = Gtk::Frame.new(tl.get_translation("frame_explanation"))
explainlabel = Gtk::Label.new
explainlabel.wrap = true
explainlabel.width_request = 400
explainlabel.set_markup(tl.get_translation("text_explanation"))
explainframe.add(explainlabel) 
lvb.pack_start_defaults explainframe

targetframe = Gtk::Frame.new(tl.get_translation("frame_directory"))
targetbutton = Gtk::FileChooserButton.new(tl.get_translation("workdir"), Gtk::FileChooser::ACTION_SELECT_FOLDER)
targetbutton.current_folder = "/media/disk"
# targetbutton.width_request = 300
targetframe.add(targetbutton) 
lvb.pack_start_defaults targetframe

outputframe = Gtk::Frame.new(tl.get_translation("frame_output"))
outputbutton = Gtk::FileChooserButton.new(tl.get_translation("workdir"), Gtk::FileChooser::ACTION_SELECT_FOLDER)
outputbutton.current_folder = "/tmp"
# targetbutton.width_request = 300
outputframe.add(outputbutton) 
lvb.pack_start_defaults outputframe

gobutton = Gtk::Button.new(tl.get_translation("go"))
gobutton.width_request = 150
progressframe = Gtk::Frame.new(tl.get_translation("frame_progress"))
pgbar = Gtk::ProgressBar.new
pgbar.text = tl.get_translation("click_start")
pgbar.width_request = 250
# pgbar.fraction = 0.7
progressbox = Gtk::HBox.new(false, 5)
progressbox.pack_start(pgbar, true, true, 0)
progressbox.pack_start(gobutton, false, true, 0)
progressframe.add(progressbox)
lvb.pack_start_defaults progressframe

gobutton.sensitive = false
targetbutton.signal_connect('selection_changed') {
	gobutton.sensitive = true unless targetbutton.filename.nil?
}

gobutton.signal_connect('clicked') {
	gobutton.sensitive = false
	targetbutton.sensitive = false
	outputbutton.sensitive = false
	pgbar.text = tl.get_translation("running")
	pgbar.pulse 
	traverse_dir(targetbutton.filename, targetbutton.filename, pgbar, outputbutton.filename)
	pgbar.fraction = 1.0
	pgbar.text = tl.get_translation("done")
	system("nohup thunar '#{outputbutton.filename}' &") 
}

window.add(lvb) 
window.set_title(tl.get_translation("title"))
window.window_position = Gtk::Window::POS_CENTER_ALWAYS

window.show_all
Gtk.main
