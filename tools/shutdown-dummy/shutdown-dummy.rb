#!/usr/bin/ruby
# encoding: utf-8

require 'rexml/document'
require 'glib2'
require 'gtk2'
# require 'vte'
require 'MfsTranslator.rb'
# require 'optparse'

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
tlfile = "shutdown-dummy.xml"
tl = MfsTranslator.new(lang, tlfile)

@entrynum = Array.new
@entryname = Array.new 
@winentry = 0
@efi = false
if system("mountpoint -q /sys/firmware/efi/efivars") 
	@efi = true
	ct = 0 
	IO.popen("sudo /usr/sbin/efibootmgr") { |line|
		while line.gets
			ltoks = $_.strip.split("* ") 
			if ltoks[0] =~ /Boot([0-9][0-9][0-9][0-9])$/ 
				@entrynum[ct] = $1
				@entryname[ct] = ltoks[1..-1].join(" ")
				@winentry = ct if ltoks[1..-1].join(" ") =~ /windows/i
				ct += 1
			end
		end
	}
end

infolabel = Gtk::Label.new(tl.get_translation("infolabel")) 
infolabel.wrap = true
vbox = Gtk::VBox.new
dropdown = Gtk::ComboBox.new
if @entrynum.size > 0
	@entryname.each { |n|
		dropdown.append_text n
	}
	dropdown.active = @winentry 
end
droplabel = Gtk::Label.new(tl.get_translation("sys2boot"))
buttonbox = Gtk::HBox.new

rbutton = Gtk::Button.new(tl.get_translation("reboot"))
sbutton = Gtk::Button.new(tl.get_translation("shutdown"))
cbutton = Gtk::Button.new(tl.get_translation("cancel"))

[ rbutton, sbutton, cbutton, dropdown].each { |w| w.height_request = 36 }
[ rbutton, sbutton, cbutton ].each { |w| 
	w.width_request = 120 
	buttonbox.pack_start_defaults w 
}
[ dropdown, infolabel, droplabel ].each { |w| w.width_request = 360 }
vbox.pack_start_defaults(infolabel)
droplabel.set_alignment(0, 0.5) 
if @entrynum.size > 0
	vbox.pack_start_defaults(droplabel)
	vbox.pack_start_defaults(dropdown)
end
vbox.pack_start_defaults(buttonbox)

window = Gtk::Window.new
window.border_width = 10 
window.signal_connect("delete_event") {
        puts "delete event occurred"
	Gtk.main_quit
        false
}

window.signal_connect("destroy") {
        puts "destroy event occurred"
        Gtk.main_quit
}

sbutton.signal_connect("clicked") { 
	system("sudo /sbin/poweroff")
	Gtk.main_quit
	exit 0
}

cbutton.signal_connect("clicked") { 
	Gtk.main_quit
	exit 0
}

rbutton.signal_connect("clicked") { 
	if @entrynum.size > 0
		system("sudo /usr/sbin/efibootmgr --bootnext #{@entrynum[dropdown.active]}")
	end
	system("sudo /sbin/poweroff")
	Gtk.main_quit
	exit 0 
}

window.set_title(tl.get_translation("wintitle"))
window.window_position = Gtk::Window::POS_CENTER_ALWAYS
window.add vbox

window.show_all
Gtk.main
