#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
require "rexml/document"
require 'MfsDiskDrive'
require 'MfsSinglePartition'
require 'MfsTranslator'

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
explainlabel.set_markup("Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.")
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



window.add(lvb) 
window.set_title(tl.get_translation("title"))
window.window_position = Gtk::Window::POS_CENTER_ALWAYS

window.show_all
Gtk.main