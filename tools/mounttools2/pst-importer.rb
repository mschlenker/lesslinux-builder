require 'glib2'
require 'gtk2'
require "rexml/document"
require 'fileutils'
require 'MfsTranslator'
require 'digest/sha1'
require 'vte'

$lastpulse = Time.now.to_f 
$histfiles = 0

def traverse_dir(startdir, basedir, pgbar, tgtdir)
	now = Time.now.to_f 
	if now > $lastpulse + 0.3
		pgbar.pulse
		pgbar.text = "Suche in " + File.basename(startdir) 
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
		elsif File.file?("#{startdir}/#{e}") && e =~ /\.pst$/ 
			convert_pst("#{startdir}/#{e}", basedir, pgbar, tgtdir) 
		end
	}
end

def run_command(pgbar, command, args, text)
        puts "Running " + command + " : " + args.join(" ")  
        pgbar.text = text 
        vte = Vte::Terminal.new
        running = true
        vte.signal_connect("child_exited") { running = false }
        vte.fork_command(command, args)
        while running == true
                pgbar.pulse
                while (Gtk.events_pending?)
                        Gtk.main_iteration
                end
                sleep 0.2 
        end
end

def convert_pst(filepath, basedir, pgbar, tgtdir)
	outdir = tgtdir + "/Outlook-Import/" + File.basename(filepath, ".pst")
	outsbd = File.basename(filepath, ".pst")
	n = 0
	while File.directory?(outdir) 
		outdir = tgtdir + "/Outlook-Import/" + File.basename(filepath, ".pst") + "." + n.to_s 
		outsbd = File.basename(filepath, ".pst") + "." + n.to_s 
		n += 1
	end
	FileUtils::mkdir_p outdir
	system("sync")
	sleep 1
	pgbar.text = "Konvertiere " + File.basename(filepath, ".pst")
	puts "Running: readpst -o \"#{outdir}\"  \"#{filepath}\""
	run_command(pgbar, "readpst", [ "readpst",  "-o" ,   outdir, filepath ], "Konvertiere " + File.basename(filepath, ".pst") ) 
	#IO.popen( "readpst -o \"#{outdir}\"  \"#{filepath}\"" ) { |line|
	#	puts line.gets
	#	now = Time.now.to_f 
	#	if now > $lastpulse + 0.3
	#		pgbar.pulse
	#		$lastpulse = now
	#	end
	#	while (Gtk.events_pending?)
	#		Gtk.main_iteration
	#	end
	#}
	# pgbar.text = tl.get_translation("running")
	FileUtils::mkdir_p "/home/surfer/.thunderbird/cdi12345.default/Mail/localhost/Inbox.sbd/Outlook-Import.sbd"
	FileUtils::touch "/home/surfer/.thunderbird/cdi12345.default/Mail/localhost/Inbox.sbd/Outlook-Import"
	FileUtils::touch "/home/surfer/.thunderbird/cdi12345.default/Mail/localhost/Inbox.sbd/Outlook-Import.sbd/" + outsbd
	puts "Running: ln -sf \"#{outdir}\" \"/home/surfer/.thunderbird/cdi12345.default/Mail/localhost/Inbox.sbd/Outlook-Import.sbd/#{outsbd}.sbd\""
	system("ln -sf \"#{outdir}\" \"/home/surfer/.thunderbird/cdi12345.default/Mail/localhost/Inbox.sbd/Outlook-Import.sbd/#{outsbd}.sbd\"")
	#shasum = Digest::SHA1.hexdigest File.new(filepath).read 
	#lines = IO.popen( ["perl", "jl.pl", filepath ]).readlines
	#outname = tgtdir + "/Win_Jumplist_" + shasum + ".txt"
	#outfile = File.new(outname, "w")
	#lines.each { |l| outfile.write(l) }
	#outfile.close
	#$histfiles += 1
	#pgbar.text = "Gefunden: #{$histfiles} Dateien"
end

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
tlfile = "pst-importer.xml"
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
	system("nohup thunderbird &") 
}

window.add(lvb) 
window.set_title(tl.get_translation("title"))
window.window_position = Gtk::Window::POS_CENTER_ALWAYS

window.show_all
Gtk.main
