#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
require "rexml/document"
require 'MfsDiskDrive'
require 'MfsSinglePartition'
require 'MfsTranslator'
require 'exifr'
require 'fileutils'
require 'id3tag'

$lastpulse = Time.now.to_f 
$actionmove = false

def traverse_dir(startdir, basedir, pgbar)
	return true if startdir == "#{basedir}/sortiert"
	now = Time.now.to_f 
	if now > $lastpulse + 0.3
		pgbar.pulse
		$lastpulse = now
	end
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	Dir.entries(startdir).each { |e|
		puts "Parsing #{startdir}/#{e}"
		if e == "." || e == ".."
			puts "Ignore directory #{e}"
		elsif File.symlink? "#{startdir}/#{e}"
			puts "Ignore symlink #{e}"
		elsif File.directory? "#{startdir}/#{e}" 
			traverse_dir("#{startdir}/#{e}", basedir, pgbar) 
		elsif File.file? "#{startdir}/#{e}"
			rename_file("#{startdir}/#{e}", basedir, pgbar) 
		end
	}
end

def rename_file(filepath, basedir, pgbar) 
		now = Time.now.to_f
		if now > $lastpulse + 0.3
			pgbar.pulse
			$lastpulse = now
		end
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		if filepath =~ /\.jpg$/i || filepath =~ /\.jpeg$/i
			img = EXIFR::JPEG.new(filepath)
			# Try to read some exif infos
			if img.exif? && !img.date_time.nil? && img.model.to_s != "" && (img.width + img.height > 1119)
				puts "Renaming #{filepath}"
				begin
					puts img.model
					puts img.width.to_s + " " + img.height.to_s
					puts img.date_time.to_i.to_s
					dest = "#{basedir}" + @tl.get_translation("path_picture") + "/#{img.date_time.year}/#{img.date_time.month}/#{img.model}"
					FileUtils::mkdir_p dest 
					if $actionmove == true
						FileUtils::mv(filepath, "#{dest}/#{img.date_time.year}_#{img.date_time.month}_#{img.date_time.day}_#{File.basename(filepath)}" )
					else
						FileUtils::cp(filepath, "#{dest}/#{img.date_time.year}_#{img.date_time.month}_#{img.date_time.day}_#{File.basename(filepath)}" )
					end
				rescue 
					puts "Broken EXIF tag!"
				end
			end
		elsif filepath =~ /\.xls/i || filepath =~ /\.csv$/i || filepath =~ /\.sxc$/i || filepath =~ /\.xlt$/i   || filepath =~ /\.ods$/i  
			dest = basedir + @tl.get_translation("path_spreadsheet")
			FileUtils::mkdir_p dest 
			if $actionmove == true
				FileUtils::mv(filepath, dest )
			else
				FileUtils::cp(filepath, dest )
			end
		elsif filepath =~ /\.doc/i || filepath =~ /\.rtf$/i || filepath =~ /\.sxw$/i || filepath =~ /\.odt$/i   || filepath =~ /\.ott$/i  
			dest = basedir + @tl.get_translation("path_wordproc")
			FileUtils::mkdir_p dest 
			if $actionmove == true
				FileUtils::mv(filepath, dest )
			else
				FileUtils::cp(filepath, dest )
			end
		elsif filepath =~ /\.ppt/i || filepath =~ /\.odp$/i || filepath =~ /\.otp$/i || filepath =~ /\.odg$/i   || filepath =~ /\.sxi$/i   || filepath =~ /\.pot$/i  
			dest = basedir + @tl.get_translation("path_presentation")
			FileUtils::mkdir_p dest 
			if $actionmove == true
				FileUtils::mv(filepath, dest )
			else
				FileUtils::cp(filepath, dest )
			end
		elsif filepath =~ /\.mp3$/i
			audio = File.open(filepath, "r") 
			tag = ID3Tag.read(audio)
			puts "Renaming #{filepath}"
			artist = tag.artist.to_s.gsub(":", ".").gsub("/", "_")
			artist = "uknown artist" if artist.to_s == ""
			album = tag.album.to_s.gsub(":", ".").gsub("/", "_")
			album = "uknown album" if album.to_s == ""
			begin
				title = tag.title.to_s.gsub(":", ".").gsub("/", "_")
			rescue 
				title = ` uuidgen `
			end
			if title.to_s == ""
				title = "uknown title" 
			end
			begin
				if tag.track_nr.to_i > 0
					title = tag.track_nr.to_i.to_s + " " + title
				end
			rescue
			end
			title = title + " " + File.basename(filepath)
			begin
				if tag.year.to_i > 0
					album = tag.year.to_i.to_s + " " + album
				end
			rescue
			end
			dest = "#{basedir}" + @tl.get_translation("path_mp3") + "/#{artist}/#{album}"
			FileUtils::mkdir_p dest 
			audio.close
			if $actionmove == true
				FileUtils::mv(filepath, "#{dest}/#{title}" )
			else
				FileUtils::cp(filepath, "#{dest}/#{title}" )
			end
		end
	end

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
tlfile = "photorec-sorter.xml"
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

actionframe = Gtk::Frame.new(tl.get_translation("frame_action"))
actionbox = Gtk::VBox.new(false, 5)
actioncopy = Gtk::RadioButton.new(tl.get_translation("action_copy"))
actionmove = Gtk::RadioButton.new(actioncopy, tl.get_translation("action_move"))
actionbox.pack_start_defaults actioncopy
actionbox.pack_start_defaults actionmove
actionframe.add actionbox
lvb.pack_start_defaults actionframe

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
	$actionmove = true if actionmove.active? 
	gobutton.sensitive = false
	actioncopy.sensitive = false
	actionmove.sensitive = false
	targetbutton.sensitive = false
	pgbar.text = tl.get_translation("running")
	pgbar.pulse 
	traverse_dir(targetbutton.filename, targetbutton.filename, pgbar)
	pgbar.fraction = 1.0
	pgbar.text = tl.get_translation("done")
	system("nohup thunar '#{targetbutton.filename}/sortiert' &") 
}

window.add(lvb) 
window.set_title(tl.get_translation("title"))
window.window_position = Gtk::Window::POS_CENTER_ALWAYS

window.show_all
Gtk.main
