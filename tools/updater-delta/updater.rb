#!/usr/bin/ruby
# encoding: utf-8

require 'gtk2'
require "rexml/document"

def download_single_file(filename)
	system("bash 000_download.sh " + filename)
	puts filename
end

def run_update (parent, pbutton, module_chunks, overlay_chunks, delta_chunks, xfile)
	parent.deletable = false
	pbutton.sensitive = false
	align = Gtk::Alignment.new(0.5, 0.5, 1.0, 0.0)
	pbar = Gtk::ProgressBar.new
	align.add(pbar)
	dialog = Gtk::Dialog.new(
		"Fortschritt der Aktualisierung",
		parent,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.vbox.add(align)
	msg = Gtk::Label.new("Die Aktualisierung läuft. Bitte haben Sie etwas Geduld!\n\n\n\n")
	msg.wrap = true
	dialog.vbox.add(msg)
	dialog.set_size_request(450, 150)
	dialog.deletable = false
	dialog.set_response_sensitive(Gtk::Dialog::RESPONSE_OK, false)
	dialog.show_all
	# show_progress(pbar, dialog, msg, usable_drives, target, syssize, contpass, userpass)
	dialog.signal_connect('response') { 
		#puts "trigger reboot here..."
		#trigger_reboot
		Gtk.main_quit 
	}
	progress_update(dialog, msg, pbar, module_chunks, overlay_chunks, delta_chunks, xfile)
end

def progress_update(dialog, msg, progress, module_chunks, overlay_chunks, delta_chunks, xfile)
	# first download all chunks
	progress.text = "Download der Aktualisierungen..."
	all_chunks = module_chunks + overlay_chunks + delta_chunks
	1.upto(module_chunks.size + overlay_chunks.size + delta_chunks.size) { |chunk|
		download_single_file(all_chunks[chunk - 1])
		progress.text = "Datei " + chunk.to_s + " von " + (all_chunks.size).to_s + " heruntergeladen..."
		progress.fraction = 0.66 / (all_chunks.size).to_f * chunk.to_f
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
	}
	# now test the sha1sums
	progress.text = "Prüfung der heruntergeladenen Dateien"
	progress.fraction = 0.70
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	chunk01_success = system("sha1sum -c chunk01.sha")
	chunk02_success = system("sha1sum -c chunk02.sha")
	chunk03_success = system("sha1sum -c chunk03.sha")
	if (chunk01_success == false || chunk02_success == false || chunk03_success == false)
		progress.fraction = 1.00
		msg.text = "Die Aktualisierungen konnten nicht heruntergeladen werden. " + 
			"Mögliche Ursachen sind zuwenig freier Speicher in /tmp oder eine instabile " + 
			"Internetverbindung. Versuchen Sie die Aktualisierung zu einem späteren Zeitpunkt erneut."
		dialog.set_response_sensitive(Gtk::Dialog::RESPONSE_OK, true)
	else
		# delete modules first
		progress.text = "Löschung alter Treiber..."
		system("bash 020_unmount_modules.sh")
		system("rm /lesslinux/cdrom/lesslinux/" + xfile.root.elements["modules"].attributes["replaces"] )
		progress.fraction = 0.72
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		# cat new modules
		progress.text = "Schreibe neue Treiber..."
		system("cat chunk01.?? > /lesslinux/cdrom/lesslinux/" + xfile.root.elements["modules"].attributes["target"] )
		progress.fraction = 0.82
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		# delete other files
		progress.text = "Lösche alte Dateien..."
		xfile.root.elements.each("delete/file") { |el|
			puts("rm /lesslinux/cdrom" + el.attributes["name"] )
			system("rm /lesslinux/cdrom" + el.attributes["name"] )
		}
		progress.fraction = 0.88
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		# unpack bootfiles
		progress.text = "Entpacke Startdateien..."
		system("bash 040_unpack_bootfiles.sh")
		progress.fraction = 0.94
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		# unpack deltas
		progress.text = "Entpacke Startdateien..."
		system("bash 060_unpack_deltas.sh")
		system("bash 070_write_version.sh")
		progress.fraction = 1.00
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		system("cp replace_updater.sh /etc/lesslinux/updater/updater.sh")
		system("chmod 0755 /etc/lesslinux/updater/updater.sh")
		msg.text = "Das Herunterladen der Updates ist abgeschlossen. Starten Sie Ihren Computer nun neu, um die Aktualisierung abzuschließen."
		dialog.set_response_sensitive(Gtk::Dialog::RESPONSE_OK, true)
	end
end

def create_tooltab
	tbox = Gtk::VBox.new(false, 5)
	delhead = Gtk::Label.new("USB-Laufwerk löschen")
	fat_font = Pango::FontDescription.new("Sans Bold 12")
	delhead.modify_font(fat_font)
	deldesc = Gtk::Label.new("Mit diesem Werkzeug können Sie ein USB-Laufwerk löschen, auf dem COMPUTERBILD Sicher surfen installiert ist. Hierbei gehen alle Daten auf diesem Laufwerk verloren.")
	deldesc.wrap = true
	delbutton = Gtk::Button.new("Löschwerkzeug starten")
	delbutton.signal_connect("clicked") { |p|
		system("ruby /tmp/lesslinux.update/stickdel.rb")
	}
	tbox.pack_start(delhead, false, true, 5)
	tbox.pack_start(deldesc, false, true, 5)
	tbox.pack_start(delbutton, false, true, 5)
	return tbox
end

# read the configuration file
xdoc = REXML::Document.new(File.new("updater.xml"))

begin
	# read the file containing the boot medium
	bootdev = File.new("/var/run/lesslinux/install_source").read
rescue
	bootdev = "/dev/sdx2"
	bootdev = "/dev/sr9"
end

target_version = xdoc.root.attributes["target"]
applies_to = xdoc.root.attributes["applies"]
modules_upto = xdoc.root.elements["modules"].attributes["end"]
modules_target = xdoc.root.elements["modules"].attributes["target"]
modules_replaces = xdoc.root.elements["modules"].attributes["replaces"]
overlays_upto = xdoc.root.elements["overlay"].attributes["end"]
deltas_upto = xdoc.root.elements["deltas"].attributes["end"]
about_text = xdoc.root.elements["info"].text

common_vars = File.new("common_vars.sh", "w")
common_vars.write("this_version=" + applies_to + "\n")
common_vars.write("that_version=" + target_version + "\n")
common_vars.close

module_chunks = Array.new
overlay_chunks = Array.new
delta_chunks = Array.new

puts target_version
file_count = 0

"a".upto("z") { |n|
	"a".upto("z") { |m|
		module_chunks.push("chunk01." + n + m) unless n + m > modules_upto
		overlay_chunks.push("chunk02." + n + m) unless n + m > overlays_upto
		delta_chunks.push("chunk03." + n + m) unless n + m > deltas_upto
	}
}

file_count = module_chunks.size + overlay_chunks.size + delta_chunks.size

chunk_width = 0.66 / file_count
puts chunk_width

window = Gtk::Window.new

fat_font = Pango::FontDescription.new("Sans Bold 12")

if bootdev =~ /^\/dev\/sd/
	button = Gtk::Button.new("Aktualisierung beginnen")
	button.signal_connect("clicked") { |pbutton|
		run_update(window, pbutton, module_chunks, overlay_chunks, delta_chunks, xdoc)
	}
	header = Gtk::Label.new("Aktualisierung beginnen")
	header.modify_font(fat_font)
	info_text = Gtk::Label.new("Bei der Aktualisierung werden ca. " + (file_count * 5).to_s  + "MB Daten heruntergeladen. " + 
		"Starten Sie den Rechner während der Aktualisierung nicht neu und schalten Sie Ihn nicht ab. ")
else
	button = Gtk::Button.new("Abbrechen")
	button.signal_connect("clicked") { |pbutton|
		 Gtk.main_quit
	}
	header = Gtk::Label.new("Aktualisierung nicht möglich")
	header.modify_font(fat_font)
	info_text = Gtk::Label.new("Die Aktualisierung ist nur möglich, wenn Sie COMPUTERBILD Sicher surfen 2009 von " + 
		"USB-Stick oder -Festplatte gestartet haben.")
end

about_label = Gtk::Label.new(about_text)
about_label.wrap = true
about_label.width_request = 400

info_text.wrap = true
info_text.width_request = 400
vbox = Gtk::VBox.new(false, 5)
vbox.pack_start(header, false, true, 5)
vbox.pack_start(about_label, false, true, 5)
vbox.pack_start(info_text, false, true, 5)
vbox.pack_start(button, false, true, 5)

window.signal_connect("delete_event") {
  puts "delete event occurred"
  #true
  false
}

window.signal_connect("destroy") {
  puts "destroy event occurred"
  Gtk.main_quit
}

window.border_width = 5
window.set_size_request(420, 300)
nb = Gtk::Notebook.new
nb.append_page(vbox, Gtk::Label.new("Aktualisierung"))
nb.append_page(create_tooltab, Gtk::Label.new("Werkzeuge"))
nb.border_width = 5
window.add(nb)
window.set_title("Aktualisierung")
window.show_all

Gtk.main
