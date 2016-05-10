#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
require "rexml/document"
require 'fileutils'
require 'MfsTranslator'
require 'digest/sha1'
require 'vte'
  
def run_qemu(button, command, args)
        puts "Running " + command + " : " + args.join(" ")  
        button.sensitive = false
        vte = Vte::Terminal.new
        running = true
        vte.signal_connect("child_exited") { running = false }
        vte.fork_command(command, args)
        while running == true
                while (Gtk.events_pending?)
                        Gtk.main_iteration
                end
                sleep 0.2 
        end
	button.sensitive = true
end
  
lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
tlfile = "qemustarter.xml"
tl = MfsTranslator.new(lang, tlfile)
@tl = tl
@drives = Array.new

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
 
optsframe = Gtk::Frame.new(tl.get_translation("frame_options"))
optsbox = Gtk::VBox.new(false, 5) 
imgbox = Gtk::HBox.new(false, 5) 
imglabel = Gtk::Label.new(tl.get_translation("image_desc"))
imgbutton = Gtk::FileChooserButton.new(tl.get_translation("workdir"), Gtk::FileChooser::ACTION_OPEN)
imgbox.pack_start_defaults imglabel
imgbox.pack_start_defaults imgbutton
optsbox.pack_start_defaults imgbox
spinbox = Gtk::HBox.new(false, 5) 
spinlabel = Gtk::Label.new(tl.get_translation("memory"))
spinbutton = Gtk::SpinButton.new(128.0, 8192.0, 64.0)
spinbutton.value = 1024.0
spinbox.pack_start_defaults spinlabel
spinbox.pack_start_defaults spinbutton
optsbox.pack_start_defaults spinbox
qcow_label = Gtk::CheckButton.new(tl.get_translation("use-qcow-overlay"))
qcow_label.active = true 
optsbox.pack_start_defaults qcow_label 
qcowbox = Gtk::HBox.new(false, 5) 
qcowbutton = Gtk::FileChooserButton.new(tl.get_translation("workdir"), Gtk::FileChooser::ACTION_CREATE)
qcowquest = Gtk::Label.new(tl.get_translation("choose-qcow"))
qcowbox.pack_start_defaults qcowquest
qcowbox.pack_start_defaults qcowbutton
optsbox.pack_start_defaults qcowbox

optsframe.add optsbox
lvb.pack_start_defaults optsframe

gobutton = Gtk::Button.new(tl.get_translation("qemustart"))
gobutton.width_request = 400
progressframe = Gtk::Frame.new(tl.get_translation("frame_progress"))
progressbox = Gtk::HBox.new(false, 5) 
progressbox.pack_start(gobutton, false, true, 0)
progressframe.add(progressbox)
lvb.pack_start_defaults progressframe
 
gobutton.sensitive = false
imgbutton.signal_connect('selection_changed') {
	gobutton.sensitive = true if File.exists? imgbutton.filename.to_s
}
 
gobutton.signal_connect('clicked') {
	args = [ "qemu-system-x86_64",  "-enable-kvm", 
		"-m",  spinbutton.value.to_i.to_s,  
		"-net", "nic", "-net",  "user",  
		"-display", "sdl", 
		"-boot",  "c", "-hda",  imgbutton.filename.to_s ]
	run_qemu(gobutton, args[0], args)
}

window.add(lvb) 
window.set_title(tl.get_translation("title"))
window.window_position = Gtk::Window::POS_CENTER_ALWAYS

window.show_all
Gtk.main
