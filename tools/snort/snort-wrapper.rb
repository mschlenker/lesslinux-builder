#!/usr/bin/ruby
# encoding: utf-8

require 'rexml/document'
require 'glib2'
require 'gtk2'
require 'vte'
# require 'MfsTranslator.rb'
require 'optparse'

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

def get_oinkcode
	return File.read("/lesslinux/blobpart/snort/oinkcode.txt").strip if File.exists?("/lesslinux/blobpart/snort/oinkcode.txt")
	return ""
end

def snort_running(button=nil)
	found = false
	IO.popen("ps waux") { |l|
		while l.gets
			found = true if $_.strip.split[10] == "snort"
		end
	}
	unless button.nil? 
		button.label = "SNORT Konsole öffnen" if found
		button.label = "SNORT starten" unless found
	end
	return found
end


lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?

# Frame for an info label
tframe = Gtk::Frame.new( "SNORT")
tlabel = Gtk::Label.new("Dieser Assistent konfiguriert das Intrusion Detection System SNORT. Um Analyseregeln herunterladen zu können ist die Erstellung eines kostenlosen Oinkcodes notwendig. Sie können dies auf der Webseite www.snort.org erledigen. Nach Eingabe des Oinkcodes können Sie Snort für die erste Benutzung vorbereiten und dann starten. Die Logdateien von Snort finden Sie im Ordner /var/log/snort.")
tlabel.wrap = true
tlabel.width_request = 580
tframe.add(tlabel)

# Frame für Regeln
rframe = Gtk::Frame.new( "Analyseregeln")
rlabel = Gtk::Label.new("Noch nie aktualisiert")
if File.exists?("/lesslinux/blobpart/snort/pulledpork_last_success") 
	mtime = File.mtime("/lesslinux/blobpart/snort/pulledpork_last_success")
	rlabel.text = "Letztes Update: " + mtime.to_s 
end
rbox = Gtk::HBox.new
rbutton = Gtk::Button.new("Jetzt aktualisieren") 
rbutton.height_request = 32
rbutton.width_request = 160
rbox.pack_start(rlabel, true, true, 0)
rbox.pack_start(rbutton, false, true, 0)
rframe.add(rbox)

# Frame for Oinkcode input field
oframe = Gtk::Frame.new( "Oinkcode")
oinput = Gtk::Entry.new
oinput.text = get_oinkcode
# rbutton.sensitive = false if oinput.text == ""
obox = Gtk::HBox.new
obutton = Gtk::Button.new("Webseite besuchen") 
obutton.height_request = 32
obutton.width_request = 160
obox.pack_start(oinput, true, true, 0)
obox.pack_start(obutton, false, true, 0)
oframe.add(obox)
#oinput.signal_connect("insert_text") {
#	if oinput.text.length > 31
#		rbutton.sensitive = true
#	else
#		rbutton.sensitive = false 
#	end
#}
#oinput.signal_connect("paste_clipboard") {
#	if oinput.text.length > 35
#		rbutton.sensitive = true
#	else
#		rbutton.sensitive = false 
#	end
#}


# Frame fürs Terminal
vframe = Gtk::Frame.new( "Ausgabe der Prozesse")
vte = Vte::Terminal.new
vte.set_font("Fixed 13", Vte::TerminalAntiAlias::FORCE_DISABLE)
vte.height_request = 150
vframe.add(vte)

gobutton = Gtk::Button.new("SNORT starten") 
gobutton.label = "SNORT-Konsole öffnen" if snort_running 
gobutton.sensitive = false unless File.exists?("/lesslinux/blobpart/snort/pulledpork_last_success") 

lvb = Gtk::VBox.new
lvb.pack_start_defaults(tframe)
lvb.pack_start_defaults(oframe)
lvb.pack_start_defaults(rframe)
lvb.pack_start_defaults(vframe)
lvb.pack_start_defaults(gobutton)
# bbox = Gtk::HBox.new

vte.signal_connect("child_exited") {
	rbutton.sensitive = true
	gobutton.sensitive = true 
	if File.exists?("/lesslinux/blobpart/snort/pulledpork_last_success") 
		mtime = File.mtime("/lesslinux/blobpart/snort/pulledpork_last_success")
		rlabel.text = "Letztes Update: " + mtime.to_s 
		gobutton.sensitive = true 
		system("killall -s SIGHUP snort") 
	end
}

rbutton.signal_connect("clicked") {
	if oinput.text.strip.size < 32
		info_dialog("Oinkcode", "Bitte geben Sie einen gültigen Oinkcode (mindestens 32 Zeichen) ein.") 
	else
		oink = File.new("/lesslinux/blobpart/snort/oinkcode.txt", "w")
		oink.write oinput.text.strip
		oink.close 
		# system("bash pulledpork.sh")
		rbutton.sensitive = false
		gobutton.sensitive = false
		vte.fork_command("bash", ["bash", "pulledpork.sh"] )
	end
}

obutton.signal_connect("clicked") {
	system("su surfer -c \"firefox https://www.snort.org/\" &")
}

gobutton.signal_connect("clicked") {
	unless snort_running(gobutton) 
		system("screen -S snort -d -m snort -c /etc/snort/etc/snort.conf -l /var/log/snort") 
		sleep 0.3
		snort_running(gobutton)
		info_dialog("SNORT-Konsole", "Es wird nun die SNORT-Konsole geöffnet. Sie können diese jederzeit schließen, der SNORT-Prozess läuft dann im Hintergrund weiter, bis Sie die Konsole erneut öffnen.") 
	end
	system("Terminal --hide-menubar -T \"SNORT Konsole\" -e \"screen -d -r snort\"")  
}

window = Gtk::Window.new
window.signal_connect("delete_event") {
        puts "delete event occurred"
        false
}

window.signal_connect("destroy") {
        puts "destroy event occurred"
        Gtk.main_quit
}

window.border_width = 10
window.width_request = 600 
window.set_title("SNORT wrapper")
window.window_position = Gtk::Window::POS_CENTER_ALWAYS
window.add lvb

window.show_all
Gtk.main