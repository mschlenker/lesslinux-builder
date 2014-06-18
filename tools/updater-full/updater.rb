#!/usr/bin/ruby
# encoding: utf-8

require 'gtk2'
require "rexml/document"

def download_single_file(filename, target_dir)
	system("bash 000_download.sh " + filename + " " + target_dir)
	puts filename
end

def check_free_space
	inst_source = nil
	File.open("/var/run/lesslinux/install_source").each { |line| inst_source = line.strip }
	# now check if we have enough free space on the system partition of the drive
	# mounted...
	IO.popen("df -P -B 1024").each { |line|
		# FIXME: hardcoded free space!
		if line.split[0].strip == inst_source && line.split[3].strip.to_i > 350_000
			return line.split[5].strip
		end
	}
	# now check if we have enough free space on the first partition of the drive
	# mounted...
	first_part = inst_source.gsub(/2$/, '1')
	IO.popen("df -P -B 1024").each { |line|
		# FIXME: hardcoded free space!
		if line.split[0].strip == first_part && line.split[3].strip.to_i > 350_000
			system("mount -o remount,rw " + first_part)
			return line.split[5].strip
		elsif line.split[0].strip == first_part && line.split[3].strip.to_i < 350_000
			# It is mounted, but too small
			return nil
		end
	}
	# now check if we have enough free space on the first partition of the drive
	# mount first
	system("mkdir /lesslinux/update_drain")
	system("mount " + first_part + " /lesslinux/update_drain")
	IO.popen("df -P -B 1024").each { |line|
		# FIXME: hardcoded free space!
		if line.split[0].strip == first_part && line.split[3].strip.to_i > 350_000
			system("mount -o remount,rw " + first_part)
			return line.split[5].strip
		elsif line.split[0].strip == first_part && line.split[3].strip.to_i < 350_000
			# It is mounted, but too small
			system("umount /lesslinux/update_drain")
			return nil
		end
	}
	return nil
end

def run_update (parent, pbutton, fulliso_chunks, iso_target_dir, xfile)
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
	progress_update(dialog, msg, pbar, fulliso_chunks, iso_target_dir, xfile)
end

def progress_update(dialog, msg, progress, fulliso_chunks, target_dir, xfile)
	#if system("test -f " + target_dir + "/update.iso") 
	#	fulliso_sha1 = String.new
	#	IO.popen("sha1sum " + target_dir + "/update.iso").each { |line| fulliso_sha1 = line.split[0].strip }
	#	if (fulliso_sha1.strip != xfile.root.elements["fulliso"].attributes["sha1sum"].strip)
	#		progress.text = "Datei update.iso bereits vorhanden..."
	#		progress.fraction = 0.66 / (fulliso_chunks.size).to_f * chunk.to_f
	#		while (Gtk.events_pending?)
	#			Gtk.main_iteration
	#		end
	#	else
	#		progress.text = "Datei update.iso vorhanden, aber defekte. Bitte löschen Sie die Datei und starten Sie die Aktualisierung erneut!"
	#		progress.fraction = 1.00 / (fulliso_chunks.size).to_f * chunk.to_f
	#		while (Gtk.events_pending?)
	#			Gtk.main_iteration
	#		end
	#		dialog.set_response_sensitive(Gtk::Dialog::RESPONSE_OK, true)
	#		system("umount " + target_dir)
	#	end
	#end
	# first download all chunks
	progress.text = "Download der Aktualisierungen..."
	1.upto(fulliso_chunks.size) { |chunk| 
		download_single_file(fulliso_chunks[chunk - 1], target_dir)
		progress.text = "Datei " + chunk.to_s + " von " + (fulliso_chunks.size).to_s + " heruntergeladen..."
		progress.fraction = 0.66 / (fulliso_chunks.size).to_f * chunk.to_f
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
	fulliso_sha1 = String.new
	IO.popen("sha1sum " + target_dir + "/update.iso").each { |line| fulliso_sha1 = line.split[0].strip }
	if (fulliso_sha1.strip != xfile.root.elements["fulliso"].attributes["sha1sum"].strip)
		progress.fraction = 1.00
		msg.text = "Die Aktualisierungen konnten nicht heruntergeladen werden. " + 
			"Mögliche Ursachen sind zuwenig freier Speicher in /tmp oder eine instabile " + 
			"Internetverbindung. Versuchen Sie die Aktualisierung zu einem späteren Zeitpunkt erneut."
		dialog.set_response_sensitive(Gtk::Dialog::RESPONSE_OK, true)
		system("umount " + target_dir)
	else
		### puts "Breakpoint reached!"
		### raise "DebugBreakPoint"
		### Mount the ISO-Image
		progress.text = "Zugriff auf Update-Paket..."
		system("mkdir /lesslinux/update_isoloop")
		free_loop = ` losetup -f ` 
		system("losetup " + free_loop.strip + " " + target_dir + "/update.iso")
		system("mount -t iso9660 " + free_loop.strip + " /lesslinux/update_isoloop")
		progress.fraction = 0.71
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		### Replace bootfiles
		system("rsync -avHP --delete /lesslinux/update_isoloop/boot/isolinux/ /lesslinux/cdrom/boot/isolinux/")
		progress.fraction = 0.77
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		### Replace syslinux.cfg
		system("rsync -avHP syslinux.cfg.de /lesslinux/cdrom/syslinux.cfg")
		system("rsync -avHP syslinux.cfg.de /lesslinux/cdrom/extlinux.conf")
		progress.fraction = 0.81
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		### Write isoupd.txt
		system("touch /lesslinux/cdrom/lesslinux/isoupd.txt")
		progress.fraction = 0.81
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		### Write version.txt
		system("rm /lesslinux/cdrom/version.txt")
		progress.fraction = 0.83
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		system("rm /lesslinux/cdrom/lesslinux/version.txt")
		progress.fraction = 0.86
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		system("rsync -avHP /lesslinux/update_isoloop/lesslinux/version.txt /lesslinux/cdrom/lesslinux/")
		progress.fraction = 0.90
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		system("cp replace_updater.sh /etc/lesslinux/updater/updater.sh")
		system("chmod 0755 /etc/lesslinux/updater/updater.sh")
		system("umount /lesslinux/update_isoloop")
		system("losetup -d " + free_loop.strip)
		system("umount " + target_dir)
		progress.fraction = 1.00
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
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
fulliso_upto = xdoc.root.elements["fulliso"].attributes["end"]
about_text = xdoc.root.elements["info"].text

common_vars = File.new("common_vars.sh", "w")
common_vars.write("this_version=" + applies_to + "\n")
common_vars.write("that_version=" + target_version + "\n")
common_vars.close

fulliso_chunks = Array.new

puts target_version
file_count = 0

0.upto(fulliso_upto.to_i) { |n|
	fulliso_chunks.push("chunk." + sprintf("%02d", n))
}

file_count = fulliso_chunks.size
chunk_width = 0.66 / file_count
puts chunk_width

iso_target_dir = check_free_space 

### Start the GUI here

window = Gtk::Window.new

fat_font = Pango::FontDescription.new("Sans Bold 12")

if bootdev =~ /^\/dev\/sd/
	button = Gtk::Button.new("Aktualisierung beginnen")
	button.signal_connect("clicked") { |pbutton|
		run_update(window, pbutton, fulliso_chunks, iso_target_dir, xdoc)
	}
	header = Gtk::Label.new("Aktualisierung beginnen")
	header.modify_font(fat_font)
	info_text = Gtk::Label.new("Bei der Aktualisierung werden ca. " + (file_count * 4).to_s  + "MB Daten heruntergeladen. " + 
		"Starten Sie den Rechner während der Aktualisierung nicht neu und schalten Sie Ihn nicht ab. ")
elsif iso_target_dir.nil?
	button = Gtk::Button.new("Abbrechen")
	button.signal_connect("clicked") { |pbutton|
		 Gtk.main_quit
	}
	header = Gtk::Label.new("Aktualisierung nicht möglich")
	header.modify_font(fat_font)
	info_text = Gtk::Label.new("Auf dem USB-Stick ist nicht genügend Platz für temporäre Dateien. Bitte schaffen Sie wenigstens 350MB freien Speicher auf einer der beiden Partitionen.")
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
