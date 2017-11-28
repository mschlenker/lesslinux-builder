#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
require 'vte'
require 'MfsTranslator'

@busydevices = Array.new 
@lastline = 0
@lastcol = 0 
@pairdevice = nil
@running = false
@firstrun = true 

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
if File.exists? "bluemousetool.xml"
	@tl = MfsTranslator.new(lang, "bluemousetool.xml")
else
	@tl = MfsTranslator.new(lang, "/usr/share/lesslinux/drivetools/bluemousetool.xml")
end

def connect_everything(term, label, window)
	return true if @running == true
	@running = true 
	term.feed_child("power on\n")
	term.feed_child("agent on\n")
	term.feed_child("default-agent\n")
	term.feed_child("pairable on\n")
	term.feed_child("scan on\n")
	# Run for max 30 minutes
	i = 1
	while i < 3600 
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		c,r = term.cursor_position
		puts c.to_s + " " + r.to_s 
		if r > @lastline 
			numrows = r - @lastline
			txt = term.get_text_range( r - numrows - 1, 0, r - 1, 79, false) 
			inline = term.get_text_range( r, 0, r , 79, false) 
			analyze_buffer(txt, inline, term, label, window)
			@lastline = r 
		end	
		if i % 120 == 0
			term.feed_child("scan on\n")
		end
		sleep 0.5
		i += 1
	end
end

def analyze_buffer(txt, inline, term, label, window)
	# @pairdevice 
	puts "Text:\n" + txt
	puts "Input line:\n" + inline
	lines = txt.split("\n") 
	if inline =~ /Confirm passkey/ 
		term.feed_child("no\n")
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
	end
	if inline =~ /Enter PIN code/
		term.feed_child("000000\n")
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
	end
	lines.each{ |l|
		if l =~ /Passkey\:\s([0-9]+)/ 
			label.set_markup("<big><big><big><big><big>#{$1}</big></big></big></big></big>")
			window.show_all
		end
		if l =~ /Pairing successful/
			term.feed_child("trust #{@pairdevice}\n")
			sleep 1.0
			term.feed_child("connect #{@pairdevice}\n")
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
		if l =~ /Icon\:\sinput-mouse/
			label.text = "Found mouse, trying to connect #{@pairdevice}"
			term.feed_child("pair #{@pairdevice}\n")
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
		if l =~ /Icon\:\sinput-keyboard/
			label.text = "Found keyboard, trying to connect #{@pairdevice}"
			term.feed_child("pair #{@pairdevice}\n")
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
		if l =~ /^\[NEW\]/ 
			@pairdevice = l.split[2]
			term.feed_child("info #{@pairdevice}\n")
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
		if l =~ /Enter PIN code/
			term.feed_child("000000\n")
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
	}
end


lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
#tlfile = "chntpwgui.xml"
#tlfile = "/usr/share/lesslinux/drivetools/chntpwgui.xml" if File.exists?("/usr/share/lesslinux/drivetools/chntpwgui.xml")
#tl = MfsTranslator.new(lang, tlfile)
#@tl = tl

msg_label = Gtk::Label.new
msg_label.wrap = true
msg_label.width_request = 250
msg_label.text = @tl.get_translation("please_enter") 

pin_label = Gtk::Label.new
pin_label.width_request = 250
pin_label.text = ""

entry_label = Gtk::Label.new
entry_label.wrap = true
entry_label.width_request = 250
entry_label.text = @tl.get_translation("test_here") 

entry = Gtk::Entry.new
entry.width_request = 250 

vte = Vte::Terminal.new
# vte.width_request = 600
# vte.height_request = 320 
vte.set_size(80, 25)  
puts vte.scrollback_lines 
vte.set_scrollback_lines 65536
vte.fork_command("bluetoothctl", [ "bluetoothctl"] ) 

button = Gtk::Button.new( Gtk::Stock::OK )
button.signal_connect("clicked") { 
	vte.feed_child("quit\n")
	Gtk.main_quit
	exit 0
}

# VBox for stacking widgets
lvb = Gtk::VBox.new
lvb.pack_start_defaults(msg_label)
lvb.pack_start_defaults(pin_label)
lvb.pack_start_defaults(entry_label)
lvb.pack_start_defaults(entry)
lvb.pack_start_defaults(button)
# lvb.pack_start_defaults(progressframe)

window = Gtk::Window.new
window.signal_connect("delete_event") {
        puts "delete event occurred"
	vte.feed_child("quit\n")
        false
	Gtk.main_quit
	exit 0
}

window.signal_connect("destroy") {
        puts "destroy event occurred"
	vte.feed_child("quit\n")
        Gtk.main_quit
	exit 0
}

window.set_title( @tl.get_translation("pinhead") )
window.signal_connect("show") {  
	window.hide_all if @firstrun == true
	@firstrun = false 
	connect_everything(vte, pin_label, window)
}
# window.window_position = Gtk::Window::POS_CENTER_ALWAYS
window.add lvb
window.show_all

Gtk.main
