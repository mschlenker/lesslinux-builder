#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
require 'vte'

def confirm_dialog(title, text)
	dialog = Gtk::Dialog.new(
		title,
		$mainwindow,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::YES, Gtk::Dialog::RESPONSE_YES ],
		[ Gtk::Stock::NO, Gtk::Dialog::RESPONSE_NO ]
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_YES
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

# Update the label showing the modification date of the signatures

def update_siglabel(label)
	sigdate = File.mtime("/opt/avg/av/var/data/incavi.avm").strftime("%d. %B %Y, %H:%M:%S")
	label.set_markup("Sie verwenden Signaturen vom <b>#{sigdate}</b>")
end

# Get the time delta for the last successful signature update

def last_signature_update
	Time.now - File.mtime("/opt/avg/av/var/data/incavi.avm")
end

# Create an array containing the parameters for scanning

def get_scan_parameters(heal, archives, pup, logdir, scandir) 
	logfile = logdir.filename + "/avg-" + Time.now.strftime("%Y%m%d-%H%M%S") + ".log"
	scan_params = Array.new
	scan_params.push("--heal") if heal.active?
	scan_params.push("--vv-backup") if heal.active?
	scan_params.push("--arc") if archives.active?
	scan_params.push("--pup2") if pup.active?
	scan_params.push("-r")
	scan_params.push(logfile)
	scan_params.push(scandir.filename)
	return scan_params, logfile
end

def analyze_log
	scanned = nil
	infected = 0
	File.open(@lastlog).each { |line|
		scanned = $1.to_i if line =~ /^Files scanned.*?(\d*?)\(/ 
		infected += $1.to_i if line =~ /^Infections found.*?(\d*?)\(/ 
		infected += $1.to_i if line =~ /^PUPs found.*?(\d*?)\(/
	}
	return scanned, infected 
end

# Update signatures

def signature_update(cancel, apply, sigbutton, vte, scanprog, siglabel)
	cancel.sensitive = false
	apply.sensitive = false
	sigbutton.sensitive = false
	running = true
	vte.signal_connect("child_exited") { running = false }
	vte.fork_command("avgupdate")
	scanprog.text = "Update der Virensignaturen läuft"
	while running == true
		scanprog.pulse
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		sleep 0.2 
	end
	scanprog.fraction = 1.0
	scanprog.text = "Update der Virensignaturen abgeschlossen"
	update_siglabel(siglabel)
	cancel.sensitive = true
	apply.sensitive = true
	sigbutton.sensitive = true
end

@cancelled = false
@lastlog = nil

# Frame for scanner settings

scanframe = Gtk::Frame.new("Einstellungen des Virenscanners")
scanbox = Gtk::VBox.new(false, 3)
heal = Gtk::CheckButton.new("Desinfizieren (mit Vorsicht benutzen!)")
scanbox.pack_start_defaults(heal)
arc = Gtk::CheckButton.new("Archive scannen")
scanbox.pack_start_defaults(arc)
pup = Gtk::CheckButton.new("Erweiterte Suche nach potentiell unerwünschter Software")
logbox = Gtk::HBox.new(false, 3)
logbutton = Gtk::FileChooserButton.new("Logdatei anpassen", Gtk::FileChooser::ACTION_SELECT_FOLDER)
logbutton.current_folder = "/tmp"
logbox.pack_start(Gtk::Label.new("Ordner für Logdatei:"), false, true, 3)
logbox.pack_start(logbutton, true, true, 3)
scanbox.pack_start_defaults(pup)
scanbox.pack_start_defaults(logbox)
startbox = Gtk::HBox.new(false, 3)
startbutton = Gtk::FileChooserButton.new("Zu scannender Ordner anpassen", Gtk::FileChooser::ACTION_SELECT_FOLDER)
startbutton.current_folder = "/media/disk"
startbox.pack_start(Gtk::Label.new("Zu scannender Ordner:"), false, true, 3)
startbox.pack_start(startbutton, true, true, 3)
scanbox.pack_start_defaults(startbox)
scanframe.add(scanbox)

# Frame for signature settings

sigframe = Gtk::Frame.new("Stand der Signaturen")
siglabel = Gtk::Label.new
update_siglabel(siglabel)
sigbox = Gtk::HBox.new(false, 5)
sigbox.pack_start(siglabel, false, true, 3)
sigframe.add(sigbox)
sigbutton = Gtk::Button.new("Jetzt aktualisieren")
sigbutton.height_request = 32
sigbox.pack_start(sigbutton, true, true, 3)

# Frame for output

outframe = Gtk::Frame.new("Ausgabe des Virenscanners")
outbox = Gtk::VBox.new(false, 3)
vte = Vte::Terminal.new
vte.set_font("Fixed 13", Vte::TerminalAntiAlias::FORCE_DISABLE)
vte.height_request = 200
vte.width_request = 600
vte.fork_command("echo", [ "echo", "Noch kein Virenscan durchgeführt!"]) 
outbox.pack_start_defaults(vte)
scanprog = Gtk::ProgressBar.new 
scanprog.fraction = 0.0
scanprog.text = "Noch kein Virenscan durchgeführt"
scanprog.width_request = 600
scanprog.height_request = 32
outbox.pack_start_defaults(scanprog)
outframe.add(outbox)

# Buttons

bbox = Gtk::HBox.new(false, 5)
cancel = Gtk::Button.new(Gtk::Stock::CANCEL)
bbox.pack_start_defaults(cancel)
apply = Gtk::Button.new(Gtk::Stock::APPLY)
bbox.pack_start_defaults(apply)

# Window

window = Gtk::Window.new
window.signal_connect("delete_event") {
        puts "delete event occurred"
        false
}

window.signal_connect("destroy") {
        puts "destroy event occurred"
	unless @lastlog.nil? 
		File.unlink(@lastlog) if File.exists?(@lastlog)
	end
        Gtk.main_quit
}

lvb = Gtk::VBox.new(false, 6)
lvb.pack_start_defaults(scanframe)
lvb.pack_start_defaults(sigframe)
lvb.pack_start_defaults(outframe)
lvb.pack_start_defaults(bbox)

window.border_width = 10
# window.width_request = 600 
window.set_title("Virenscan mit AVG Antivirus Free")
window.window_position = Gtk::Window::POS_CENTER_ALWAYS
window.add lvb

# Wire some actions:

sigbutton.signal_connect("clicked") {
	signature_update(cancel, apply, sigbutton, vte, scanprog, siglabel)
}

apply.signal_connect("clicked") {
	if last_signature_update > 86400.0 
		signature_update(cancel, apply, sigbutton, vte, scanprog, siglabel) if confirm_dialog("Veraltete Virensignaturen", "Ihre Virensignaturen sind älter als 24 Stunden. Soll jetzt ein Update durchgeführt werden? Bitte stellen Sie eine Internetverbindung her, bevor Sie auf \"Ja\" klicken.")
	end
	if startbutton.filename == "/media/disk" || startbutton.filename == "/media"
		info_dialog("Zu scannendes Verzeichnis auswählen", "AVG Antivirus uberschreitet keine Laufwerksgrenzen. Bitte wählen Sie den Unterordner, der dem zu untersuchenden Laufwerk entspricht - beispielsweise sda2.")
	else
		[ apply, heal, sigbutton, arc, pup, logbutton, startbutton ].each { |w| w.sensitive = false }
		unless @lastlog.nil? 
			File.unlink(@lastlog) if File.exists?(@lastlog)
		end
		@cancelled = false
		scan_params, @lastlog = get_scan_parameters(heal, arc, pup, logbutton, startbutton)
		running = true
		vte.signal_connect("child_exited") { running = false }
		vte.fork_command("avgscan", [ "avgscan" ] + scan_params)
		scanprog.text = "Virenscan läuft"
		while running == true
			scanprog.pulse
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			sleep 0.2 
		end
		scanned, infected = analyze_log 
		scanprog.fraction = 1.0
		scanprog.text = "Virenscan abgeschlossen"
		scanprog.text = "Virenscan abgebrochen" if @cancelled == true
		if scanned.nil?
			info_dialog("Unvollständige Logdatei", "Die Logdatei ist unvollständig und konnte daher nicht analysiert werden. Bitte wiederholen Sie den Scan mit anderen Einstellungen!")
		elsif infected < 1 
			info_dialog("Keine Schadsoftware gefunden", "Es wurde keine Schadsoftware gefunden.")
		else 
			if confirm_dialog("Schadsoftware gefunden", "In #{scanned.to_s} untersuchten Dateien wurden #{infected.to_s} Schadprogramme gefunden. Wollen Sie die Protokolldatei ansehen und gegebenenfalls sichern?")
				system("nohup scite #{@lastlog} &")
				@lastlog = nil
			end
		end
		[ apply, heal, sigbutton, arc, pup, logbutton, startbutton ].each { |w| w.sensitive = true }
	end
}

cancel.signal_connect("clicked") {
	system("killall avgscan") 
	@cancelled = true
}

window.show_all
Gtk.main
