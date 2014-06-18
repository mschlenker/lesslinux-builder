#!/usr/bin/ruby

require 'gtk2'
require "rexml/document"

# define some common functions

class UsbDrive
	@device
	@vendor
	@product
	@size
	@partitions
	def initialize(dev)
		@device = dev
		@partitions = Hash.new
		@size = 0
		@vendor = "?"
		@product = "?"
	end
	attr_accessor :device, :vendor, :product, :partitions, :size
end

class UsbDrivePartition
	@device
	@size
	@version
	@mounted
	@mountpoint
	def initialize(dev)
		@size = 0
		@device = dev
		@mounted = false
		# now find mounted partitions
		IO.popen("mount") { |i|
			while i.gets
				tokens = $_.split
				if tokens[0] == dev
					@mounted = true
					@mountpoint = tokens[2]
				end
			end
		}
	end
	attr_accessor :device, :size, :version, :mounted, :mountpoint
end

def get_usbdrives_lshw
	all_drives = Hash.new
	xstring = ""
	begin
		IO.popen("lshw-static -xml") { |ioin|
			while ioin.gets
				xstring = xstring + $_
			end
		}
		xdoc = REXML::Document.new(xstring)
	rescue
		xdoc = REXML::Document.new("<empty><nix></nix></empty>")
	end
	# xdoc = REXML::Document.new(File.new("/tmp/lshw_sf2.xml"))
	xdoc.root.elements.each("//node[@class='storage']") { |x|
		begin
			businfo = "unknown"
			begin
				businfo = x.elements["businfo"].text.to_s
			rescue
			end
			x.elements.each("node[@class='disk']") { |element|
					if element.elements["logicalname"].text =~ /^\/dev\/sd/ && businfo =~ /^usb/
						# puts element.elements["logicalname"].text
						udrive = UsbDrive.new(element.elements["logicalname"].text)
						begin
							udrive.vendor = x.elements["vendor"].text
							udrive.product = x.elements["product"].text
						rescue
						end
						udrive.size = element.elements["size"].text.to_i
						all_parts = Hash.new
						element.elements.each("node[@class='volume']") { |vol|
							if vol.attributes["id"] =~ /^volume/  && vol.elements["description"].text =~ /fat/i
								begin
									npart = UsbDrivePartition.new(vol.elements["logicalname"].text)
									# puts vol.elements["logicalname"].text
									npart.size = vol.elements["capacity"].text.to_i
									puts vol.elements["capacity"].text.to_i
									npart.version = ""
									all_parts[vol.elements["logicalname"].text] = npart
								rescue
								end
							end
						}
						udrive.partitions = all_parts
						all_drives[element.elements["logicalname"].text] = udrive
					end
			}
			x.elements.each("node[@class='volume']") { |element|
				if element.elements["logicalname"].text =~ /^\/dev\/sd/ && businfo =~ /^usb/
					udrive = UsbDrive.new(element.elements["logicalname"].text)
					begin
						udrive.vendor = x.elements["vendor"].text
						udrive.product = x.elements["product"].text
					rescue
					end
				end
				udrive.size = element.elements["size"].text.to_i
				all_drives[element.elements["logicalname"].text] = udrive unless 
					all_drives.has_key?( element.elements["logicalname"].text )
			}
		rescue
		end
	}
	return all_drives
end

def create_drivelist(combobox, rows, usbdrives)
	(rows - 1).downto(0) { |i| 
		puts "removing " + i.to_s
		combobox.remove_text(i)
	}
	comborows = 0
	usable_drives = []
	usbdrives.each { |key, val| 
		if val.size > 900_000_000
			puts "create drivelist entry " + key
			# Use Gigabytes if the drive is 8GB or larger 
			if val.size > 7_900_000_000
				sizestr = ((val.size.to_f / 1073741824 ) + 0.5).to_i.to_s + "GB"
			else
				sizestr = (val.size.to_f / 1048576 ).to_i.to_s + "MB"
			end
			combobox.append_text( val.vendor + " " + val.product + " " + sizestr )
			usable_drives.push(val)
		end
	}
	combobox.active = 0
	return usable_drives
end

#

def check_mount(usb_drive)
	return true if system("mount | grep " + usb_drive.device)
	usb_drive.partitions.each { |p|
		puts "checking " + p.to_s
		return true if p[1].mounted == true
	}
	return false
end

def show_error_mounted(parent)
	dialog = Gtk::Dialog.new(
		"Deinstallation nicht möglich",
		parent,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.has_separator = false
	label = Gtk::Label.new("Das ausgewählte Laufwerk befindet sich im Zugriff. Falls es sich um das Startlaufwerk handelt, starten Sie den Computer bitte von Sicher surfen CD und führen Sie in dieser die Deinstallation durch.")
	label.wrap = true
	image = Gtk::Image.new(Gtk::Stock::DIALOG_ERROR, Gtk::IconSize::DIALOG)

	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image);
	hbox.pack_start_defaults(label);

	dialog.vbox.add(hbox)
	dialog.show_all
	dialog.run
	dialog.destroy
end

def find_llfiles(usb_drive)
	system("mkdir /tmp/.lldestroy")
	llfound = false
	usb_drive.partitions.each { |p|
		system("mount -o ro " + p[0] + " /tmp/.lldestroy")
		if File.exist?("/tmp/.lldestroy/syslinux.cfg") && File.exist?("/tmp/.lldestroy/version.txt")
			llfound = true
		end
		system("umount /tmp/.lldestroy")
	}
	return llfound
end

def show_info_nothing(parent)
	dialog = Gtk::Dialog.new(
		"Sicher surfen nicht gefunden",
		parent,
		Gtk::Dialog::MODAL,
		[Gtk::Stock::OK, Gtk::Dialog::RESPONSE_ACCEPT],
		[Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL]
	)
	dialog.has_separator = false
	label = Gtk::Label.new("Auf dem ausgewählten Laufwerk wurden keine Dateien von Sicher surfen 2009 gefunden. Soll der Löschvorgang dennoch fortgesetzt werden? Achtung: hierbei werden alle Daten auf dem Laufwerk unwiderruflich gelöscht!")
	label.wrap = true
	image = Gtk::Image.new(Gtk::Stock::DIALOG_WARNING, Gtk::IconSize::DIALOG)

	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image);
	hbox.pack_start_defaults(label);

	dialog.default_response = Gtk::Dialog::RESPONSE_CANCEL
	dialog.vbox.add(hbox)
	dialog.show_all
	retval = false
	dialog.run { |res|
		if res == Gtk::Dialog::RESPONSE_ACCEPT
			retval = true
		end
	}
	dialog.destroy
	return retval
end

def show_warning(parent)
	dialog = Gtk::Dialog.new(
		"Löschung bestätigen",
		parent,
		Gtk::Dialog::MODAL,
		[Gtk::Stock::OK, Gtk::Dialog::RESPONSE_ACCEPT],
		[Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL]
	)
	dialog.has_separator = false
	label = Gtk::Label.new("Soll das ausgewählte Laufwerk gelöscht und auf volle Größe zurückgesetzt werden? Achtung: hierbei werden alle Daten auf dem Laufwerk unwiderruflich gelöscht!")
	label.wrap = true
	image = Gtk::Image.new(Gtk::Stock::DIALOG_WARNING, Gtk::IconSize::DIALOG)

	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image);
	hbox.pack_start_defaults(label);

	dialog.default_response = Gtk::Dialog::RESPONSE_CANCEL
	dialog.vbox.add(hbox)
	dialog.show_all
	retval = false
	dialog.run { |res|
		if res == Gtk::Dialog::RESPONSE_ACCEPT
			retval = true
		end
	}
	dialog.destroy
	return retval
end

def run_uninstall(usb_drive, newfs, parent)
	system("mkdir /tmp/.lldestroy")
	usb_drive.partitions.each { |p|
		system("mount -o rw " + p[0] + " /tmp/.lldestroy")
		if File.exist?("/tmp/.lldestroy/home.llc")
			free_loop = "/dev/loop9999" # nil
			IO.popen("losetup -f") { |i| 
				while i.gets
					free_loop = $_.to_s.strip
				end
			}
			system("losetup " + free_loop + " '/tmp/.lldestroy/home.llc' ")
			system("mdev -s")
			system("dd if=/dev/zero bs=1M count=16 of=" + free_loop)
			system("losetup -d " + free_loop)
		end
		system("umount /tmp/.lldestroy")
	}
	system("dd if=/dev/zero bs=1M count=4 of=" + usb_drive.device)
	if (newfs == true)
		system("mkfs.msdos -F 32 -I " + usb_drive.device)
	end
	# OK und jetzt einen Dialog anzeigen:
	dialog = Gtk::Dialog.new(
		"Löschung erfolgt",
		parent,
		Gtk::Dialog::MODAL,
		[Gtk::Stock::OK, Gtk::Dialog::RESPONSE_ACCEPT]
	)
	dialog.has_separator = false
	label = Gtk::Label.new("Das ausgewählte Laufwerk wurde gelöscht. Sie können nun weitere USB-Laufwerke löschen oder das Programm beenden.")
	label.wrap = true
	image = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)

	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image);
	hbox.pack_start_defaults(label);

	dialog.vbox.add(hbox)
	dialog.show_all
	retval = false
	dialog.run { |res|
		if res == Gtk::Dialog::RESPONSE_ACCEPT
			retval = true
		end
	}
	dialog.destroy
	return retval
end

alldrives = get_usbdrives_lshw
usable_drives = []

mainwin = Gtk::Window.new
mainwin.set_size_request(400, -1)
mainwin.border_width = 10
mainwin.title = "Sicher surfen deinstallieren"

mainwin.signal_connect("destroy") {
	puts "destroy event occurred"
	Gtk.main_quit
}

button = Gtk::Button.new("Deinstallation starten")
button.sensitive = false

toplabel = Gtk::Label.new("Sicher surfen deinstallieren")
fat_font = Pango::FontDescription.new("Sans Bold 12")
toplabel.modify_font(fat_font)
desclabel = Gtk::Label.new("Wählen Sie das zu löschende USB-Laufwerk aus:")
desclabel.wrap = true
combobox = Gtk::ComboBox.new
usable_drives = create_drivelist(combobox, 0, alldrives)
button.sensitive = true if usable_drives.size > 0
formatlabel = Gtk::Label.new("Soll das zu löschende USB-Laufwerk neu formatiert werden?")
formatlabel.wrap = true
radio1 = Gtk::RadioButton.new("Ja, mit FAT32 formatieren")
# radio1.wrap = true
radio2 = Gtk::RadioButton.new(radio1, "Nein, unpartitioniert und -formatiert belassen")
# radio2.wrap = true

button.signal_connect("clicked") {
	retval = false
	if check_mount(usable_drives[combobox.active]) == true
		show_error_mounted(mainwin)
	elsif find_llfiles(usable_drives[combobox.active]) == false
		retval = show_info_nothing(mainwin)
	else
		retval = show_warning(mainwin)
	end
	if retval == true
		combobox.sensitive = false
		radio1.sensitive = false
		radio2.sensitive = false
		button.sensitive = false
		run_uninstall(usable_drives[combobox.active], radio1.active?, mainwin)
		combobox.sensitive = true
		radio1.sensitive = true
		radio2.sensitive = true
		button.sensitive = true
	end
	
}

lbox = Gtk::VBox.new(false, 10)
lbox.pack_start(toplabel, true, true, 0)
lbox.pack_start(desclabel, true, true, 0)
lbox.pack_start(combobox, true, true, 0)
lbox.pack_start(formatlabel, true, true, 0)
lbox.pack_start(radio1, true, true, 0)
lbox.pack_start(radio2, true, true, 0)
lbox.pack_start(button, true, true, 0)

mainwin.add(lbox)
mainwin.show_all

Gtk.main