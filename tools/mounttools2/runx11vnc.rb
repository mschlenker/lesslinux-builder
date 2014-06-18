#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
# require 'MfsDiskDrive.rb'
# require 'MfsSinglePartition.rb'
require 'MfsTranslator.rb'

def error_dialog(title, text) 
	dialog = Gtk::Dialog.new(
		title,
		$mainwindow,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_OK
	dialog.has_separator = false
	label = Gtk::Label.new
	label.set_markup(text)
	label.wrap = true
	image = Gtk::Image.new(Gtk::Stock::DIALOG_ERROR, Gtk::IconSize::DIALOG)
	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image)
	hbox.pack_start_defaults(label)
	dialog.vbox.add(hbox)
	dialog.show_all
	dialog.run { |resp|
		dialog.destroy
		return true
	}
end

def info_dialog(title, text) 
	dialog = Gtk::Dialog.new(
		title,
		$mainwindow,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_OK
	dialog.has_separator = false
	label = Gtk::Label.new
	label.set_markup(text)
	label.wrap = true
	image = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image)
	hbox.pack_start_defaults(label)
	dialog.vbox.add(hbox)
	dialog.show_all
	dialog.run { |resp|
		dialog.destroy
		return true
	}
end

def question_dialog(title, text, default=false)
	dialog = Gtk::Dialog.new(
		title,
		$mainwindow,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::YES, Gtk::Dialog::RESPONSE_YES ],
		[ Gtk::Stock::NO, Gtk::Dialog::RESPONSE_NO ]
	)
	if default == true
		dialog.default_response = Gtk::Dialog::RESPONSE_YES
	else
		dialog.default_response = Gtk::Dialog::RESPONSE_NO
	end
	dialog.has_separator = false
	label = Gtk::Label.new
	label.set_markup(text)
	label.wrap = true
	image = Gtk::Image.new(Gtk::Stock::DIALOG_WARNING, Gtk::IconSize::DIALOG)
	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image)
	hbox.pack_start_defaults(label)
	dialog.vbox.add(hbox)
	dialog.show_all
	dialog.run { |resp|
		case resp
		when Gtk::Dialog::RESPONSE_YES
			dialog.destroy
			return true
		else
			dialog.destroy
			return false
		end
	}
end

def check_x11vnc 
	running = false
	reverse = false
	revhost = nil
	password = nil
	IO.popen("ps waux") { |line|
		while line.gets 
			ltoks = $_.strip.split
			0.upto(9) { |n| ltoks.delete_at(0) }
			if ltoks[0] == "x11vnc" 
				puts ltoks.join(" ") 
				running = true
				if ltoks.include?("-connect") 
					reverse = true
					revhost = ltoks[ ltoks.index("-connect") + 1 ] 
				end
				if ltoks.include?("-passwd")
					password = ltoks[ ltoks.index("-passwd") + 1 ] 
				end
			end
		end
	}
	return running, reverse, revhost, password
end

def set_active_boxes(locradio, pwentry, revradio, hostentry, infofield, button)
	xvncact, xvncrev, revhost, password = check_x11vnc
	if xvncact == true
		if xvncrev == true
			revradio.active = true
			hostentry.text = revhost.strip 
		else
			locradio.active = true
		end
		unless password.nil?
			@pwentered = true
			pwentry.text = password
			pwentry.visibility = false 
		end
		locradio.sensitive = false
		pwentry.sensitive = false
		revradio.sensitive = false
		hostentry.sensitive = false
		button.label = @tl.get_translation("stopvnc")
		button.image = Gtk::Image.new(Gtk::Stock::CANCEL, Gtk::IconSize::BUTTON)
		infofield.set_markup(@tl.get_translation("vncactive"))
	else
		if locradio.active? == true
			locradio.sensitive = true
			pwentry.sensitive = true
			revradio.sensitive = true
			hostentry.sensitive = false
		else
			locradio.sensitive = true
			pwentry.sensitive = false
			revradio.sensitive = true
			hostentry.sensitive = true
		end
		button.label = @tl.get_translation("startvnc")
		button.image = Gtk::Image.new(Gtk::Stock::APPLY, Gtk::IconSize::BUTTON)
		infofield.set_markup(@tl.get_translation("vncnotactive"))
	end
end

def startx11vnc(locradio, pwentry, revradio, hostentry)
	if locradio.active? == true
		if pwentry.text == "" || @pwentered == false
			if question_dialog(@tl.get_translation("nopwdhead"), @tl.get_translation("nopwdbody"))  
				system("x11vnc -loop &")
			else
				return 1 
			end
		else
			system("x11vnc -passwd \"#{pwentry.text}\" -loop &") 
		end
	else
		if hostentry.text =~ /\s/ 
			error_dialog(@tl.get_translation("nospacehead"), @tl.get_translation("nospacebody")) 
			return false
		end
		system("x11vnc -connect \"#{hostentry.text}\" -loop &") 
	end
end

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
tlfile = "runx11vnc.xml"
tlfile = "/usr/share/lesslinux/drivetools/runx11vnc.xml" if File.exists?("/usr/share/lesslinux/drivetools/runx11vnc.xml")
tl = MfsTranslator.new(lang, tlfile)
@tl = tl

# Global variables

@pwentered = false

# Frame for Radiobutton and password field

cframe = Gtk::Frame.new(tl.get_translation("step1"))
cbox = Gtk::VBox.new(false, 5)
locradio = Gtk::RadioButton.new(tl.get_translation("local"))
pwentry = Gtk::Entry.new
pwentry.text = tl.get_translation("password")
revradio = Gtk::RadioButton.new(locradio, tl.get_translation("reverse"))
hostentry = Gtk::Entry.new
hostentry.text =  tl.get_translation("hostport")
cbox.pack_start_defaults locradio
cbox.pack_start_defaults pwentry
cbox.pack_start_defaults revradio
cbox.pack_start_defaults hostentry
cframe.add(cbox)

# Frame for Status and Go-Button

uframe = Gtk::Frame.new(tl.get_translation("step2"))
ubox = Gtk::VBox.new(false, 5)
gostop = Gtk::Button.new(tl.get_translation("startvnc"))
gostop.height_request = 32
gostop.width_request = 400
staterunning = Gtk::Label.new
staterunning.wrap = true
staterunning.width_request = 400
staterunning.set_markup(tl.get_translation("vncnotactive"))
ubox.pack_start_defaults(staterunning) 
ubox.pack_start_defaults(gostop) 
uframe.add(ubox)

# VBox for stacking widgets

lvb = Gtk::VBox.new
lvb.pack_start_defaults(cframe)
lvb.pack_start_defaults(uframe)
# lvb.pack_start_defaults(progressframe)

window = Gtk::Window.new
window.border_width = 10
window.set_title(tl.get_translation("head"))
window.window_position = Gtk::Window::POS_CENTER_ALWAYS
# window.deletable = false
# window.decorated = false
# window.width_request = 600
# window.height_request = 400
window.add lvb

window.signal_connect("delete_event") {
        puts "delete event occurred"
        false
}

window.signal_connect("destroy") {
        puts "destroy event occurred"
        Gtk.main_quit
}

gostop.signal_connect("clicked") {
	running, reverse, revhost = check_x11vnc
	if running == true
		system("killall -9 x11vnc") 
	else
		startx11vnc(locradio, pwentry, revradio, hostentry)
	end
	sleep 1
	set_active_boxes(locradio, pwentry, revradio, hostentry, staterunning, gostop)
}

locradio.signal_connect("clicked") { 
	set_active_boxes(locradio, pwentry, revradio, hostentry, staterunning, gostop)
}
revradio.signal_connect("clicked") { 
	set_active_boxes(locradio, pwentry, revradio, hostentry, staterunning, gostop)
}

pwentry.signal_connect("focus-in-event") {
	pwentry.visibility = true 
	if @pwentered == false
		pwentry.text = ""
		@pwentered = true 
	end
}

pwentry.signal_connect("focus-out-event") {
	if @pwentered == true
		pwentry.visibility = false 
	end
}

set_active_boxes(locradio, pwentry, revradio, hostentry, staterunning, gostop)
window.show_all
# shutdown.grab_default
# shutdown.grab_focus

Gtk.main