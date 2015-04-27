#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
require "rexml/document"
require 'MfsDiskDrive'
require 'MfsSinglePartition'
require 'MfsTranslator'

def traverse_dir(startdir, basedir) 
	Dir.entries.each(startdir) { |e|
		puts "Parsing #{startdir}/#{e}"
		if File.directory? "#{startdir}/#{e}"
			traverse_dir("#{startdir}/#{e}", basedir) 
		elsif File.file? "#{startdir}/#{e}"
			rename_file("#{startdir}/#{e}", basedir) 
		end
	}
end

def rename_file(filepath, basedir) 
	puts "Renaming #{filepath}"
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
explainlabel.width_request = 360
explainlabel.set_markup(tl.get_translation("text_explanation"))
explainframe.add(explainlabel) 
lvb.pack_start_defaults explainframe

targetframe = Gtk::Frame.new(tl.get_translation("frame_directory"))
targetbutton = Gtk::FileChooserButton.new(tl.get_translation("workdir"), Gtk::FileChooser::ACTION_SELECT_FOLDER)
targetbutton.current_folder = "/media/disk"
# targetbutton.width_request = 300
targetframe.add(targetbutton) 
lvb.pack_start_defaults targetframe

gobutton = Gtk::Button.new(tl.get_translation("go"))
gobutton.width_request = 120
progressframe = Gtk::Frame.new(tl.get_translation("frame_progress"))
pgbar = Gtk::ProgressBar.new
pgbar.text = tl.get_translation("click_start")
pgbar.width_request = 240
# pgbar.fraction = 0.7
progressbox = Gtk::HBox.new(false, 5)
progressbox.pack_start(pgbar, true, true, 0)
progressbox.pack_start(gobutton, false, true, 0)
progressframe.add(progressbox)
lvb.pack_start_defaults progressframe

go.signal_connect('clicked') {
	traverse_dir(targetbutton.filename, targetbutton.filename) 
}

window.add(lvb) 
window.set_title(tl.get_translation("title"))
window.window_position = Gtk::Window::POS_CENTER_ALWAYS

window.show_all
Gtk.main