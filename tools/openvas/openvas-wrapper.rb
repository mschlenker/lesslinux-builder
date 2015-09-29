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

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
# tlfile = "blobinstall.xml"
# tlfile = "/usr/share/lesslinux/drivetools/blobinstall.xml" if File.exists?("/usr/share/lesslinux/drivetools/blobinstall.xml")
# tl = MfsTranslator.new(lang, tlfile)

# Frame for an info label
tframe = Gtk::Frame.new( "OpenVAS")
tlabel = Gtk::Label.new("Dieser Assistent konfiguriert OpenVAS und lädt dafür die benötigten Schwachstellendatenbanken herunter oder aktualisiert diese sofern bereits vorhanden. Das Downloadvolumen beträgt mehrere hundert Megabyte, auf USB-Stick werden schließlich ca. 1,5GB belegt.\n\nKlicken Sie auf \"Anwenden\" um fortzufahren.")
tlabel.wrap = true
tlabel.width_request = 580
tframe.add(tlabel)

# Frame for installation progress
iframe = Gtk::Frame.new( "Fortschritt" ) # tl.get_translation("progress"))
vte = Vte::Terminal.new
vte.set_font("Fixed 13", Vte::TerminalAntiAlias::FORCE_DISABLE)
vte.height_request = 150
iframe.add(vte)
# vte.fork_command("top")

window = Gtk::Window.new
window.signal_connect("delete_event") {
        puts "delete event occurred"
        false
}

window.signal_connect("destroy") {
        puts "destroy event occurred"
        Gtk.main_quit
}

lvb = Gtk::VBox.new
lvb.pack_start_defaults(tframe)
lvb.pack_start_defaults(iframe)
bbox = Gtk::HBox.new

cancel = Gtk::Button.new(Gtk::Stock::CANCEL)
bbox.pack_start_defaults(cancel)
apply = Gtk::Button.new(Gtk::Stock::APPLY)
bbox.pack_start_defaults(apply)
lvb.pack_start_defaults(bbox)

apply.signal_connect("clicked") {
	apply.sensitive = false
	cancel.sensitive = false
	running = true
	vte.signal_connect("child_exited") { running = false }
	vte.fork_command("bash", ["bash", "/usr/bin/openvas-headless.sh"] )
	while running == true
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		sleep 0.2 
	end
	info_dialog("OpenVAS-Login", "Firefox wird nun mit dem Login zur OpenVAS-Management-Konsole gestartet. Melden Sie sich als Nutzer \"lesslinux\" mit Passwort \"lesslinux\" an.")
	system("nohup su surfer -c 'firefox http://127.0.0.1:9392/' &")
	sleep 2.0
	Gtk.main_quit
}

cancel.signal_connect("clicked") {
	Gtk.main_quit
}

if system("mountpoint -q /lesslinux/blobpart") 
	puts "OK, blobpart found"
else
	info_dialog("System im RAM", "Das Betriebssystem wird momentan im Arbeitsspeicher ausgeführt. OpenVAS benötigt rund 1,5GB Systemdateien. Wir empfehlen daher, zunächst die Installation auf USB-Stick vorzunehmen und das System dann erneut zu starten. Falls Sie über 6GB RAM oder mehr verfügen, können Sie dennoch fortfahren - Sie verlieren dann aber beim Neustart die heruntergeladenen Dateien!")
end

window.border_width = 10
window.width_request = 600 
window.set_title("OpenVAS installer")
window.window_position = Gtk::Window::POS_CENTER_ALWAYS
window.add lvb

window.show_all
Gtk.main
