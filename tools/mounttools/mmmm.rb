#!/usr/bin/ruby
# encoding: utf-8

require "rexml/document"
require 'glib2'
require 'gtk2'

#============================================================================
# define some global variables we might use later
#============================================================================

$password = nil
$dialog_success = false
$dummy = false

#============================================================================
# localization
#============================================================================

LANGUAGE = ENV['LANGUAGE'][0..1]
LOCSTRINGS = {
	"de" => {
		"pw_title" => "Passwort",
		"pw_password" => "Passwort:",
		"pw_desc" => "Diese Aktion erfordert ein Passwort!",
		"pan_usbdrive" => "USB-Laufwerk",
		"pan_sysdrive" => "Systemlaufwerk",
		"pan_stick" => "USB-Stick",
		"pan_part" => "Partition",
		"pan_optical" => "CD/DVD",
		"pan_layout" => "%DRIVE% %ACTION%",
		"pan_mount" => "einbinden",
		"pan_umount" => "lösen",
		"pan_mount_error" => "Zugriff fehlgeschlagen oder abgebrochen.",
		"pan_umount_error" => "Lösen der Laufwerkseinbindung fehlgeschlagen. Bitte stellen Sie sicher, dass kein weiterer Prozess auf das Laufwerk zugreift.",
		"pan_show" => "Inhalt anzeigen",
		"pan_writable" => "schreibbar?",
		"win_title" => "Laufwerke"
	},
	"en" => {
		"pw_title" => "Password",
		"pw_password" => "Password:",
		"pw_desc" => "This action requires a password!",
		"pan_usbdrive" => "USB drive",
		"pan_sysdrive" => "System drive",
		"pan_stick" => "USB stick",
		"pan_part" => "partition",
		"pan_optical" => "CD/DVD",
		"pan_layout" => "%ACTION% %DRIVE%",
		"pan_mount" => "Mount",
		"pan_umount" => "Unmount",
		"pan_mount_error" => "Mount failed or cancelled.",
		"pan_umount_error" => "Unmounting of the selected drive failed. Please make sure that no other process currently accesses the drive.",
		"pan_show" => "Show content",
		"pan_writable" => "writable?",
		"win_title" => "Disks"
	},
	"ru" => {
                "pw_title" => "Пароль",
                "pw_password" => "Пароль:",
                "pw_desc" => "Для выполнения этого действия требуется пароль!",
                "pan_usbdrive" => "USB-накопитель",
                "pan_sysdrive" => "Системный диск",
                "pan_stick" => "Флэш-накопитель",
                "pan_part" => "раздел",
                "pan_optical" => "CD/DVD",
                "pan_layout" => "%ACTION% %DRIVE%",
                "pan_mount" => "Монтировать",
                "pan_umount" => "Демонтировать",
                "pan_mount_error" => "Ошибка при монтировании или отмена.",
                "pan_umount_error" => "Ошибка при демонтировании выбранного устройства. Пожалуйста, убедитесь, что устройство не используется другими программами.",
                "pan_show" => "Показать содержимое",
                "pan_writable" => "перезаписываемый?",
                "win_title" => "Диски"
        },
	"es" => {
                "pw_title" => "Contraseña",
                "pw_password" => "Contraseña:",
                "pw_desc" => "Esta acción requiere una contraseña",
                "pan_usbdrive" => "Disco USB",
                "pan_sysdrive" => "Disco de sistema",
                "pan_stick" => "Memoria USB",
                "pan_part" => "partición",
                "pan_optical" => "CD/DVD",
                "pan_layout" => "%ACTION% %DRIVE%",
                "pan_mount" => "Montar",
                "pan_umount" => "Desmontar",
                "pan_mount_error" => "Montaje fallido o cancelado.",
                "pan_umount_error" => "Fallo en el desmontaje del disco seleccionado. Por favor, asegúrate de que no hay otro proceso en marcha accediendo al disco.",
                "pan_show" => "Mostrar contenido",
                "pan_writable" => "¿escribible?",
                "win_title" => "Discos"
        },
	"pl" => {
                "pw_title" => "Hasło",
                "pw_password" => "Hasło:",
                "pw_desc" => "Ta czynność wymaga podania hasła!",
                "pan_usbdrive" => "Dysk USB",
                "pan_sysdrive" => "Dysk systemowy",
                "pan_stick" => "Nośnik USB",
                "pan_part" => "partycja",
                "pan_optical" => "CD/DVD",
                "pan_layout" => "%ACTION% %DRIVE%",
                "pan_mount" => "Montuj",
                "pan_umount" => "Odmontuj",
                "pan_mount_error" => "Montowanie nie powiodło się lub zostało anulowane.",
                "pan_umount_error" => "Odmontowywanie nie powiodło się. Upewnij się, że żaden proces nie korzysta z wybranego napędu.",
                "pan_show" => "Pokaż zawartość",
                "pan_writable" => "dozwolony zapis?",
                "win_title" => "Dyski"
        }
}

def extract_lang_string(string_id)
	lang = "en"
	lang = LANGUAGE unless LANGUAGE.nil?
	message_string = "message not found: " + string_id
	begin
		message_string = LOCSTRINGS['en'][string_id]
	rescue
	end
	begin
		message_string = LOCSTRINGS[lang][string_id]
	rescue
	end
	return message_string #.gsub('%BRANDLONG%', get_brandlong)
end

#============================================================================
# core logic
#============================================================================

def read_devs
	xml_obj = nil
	if ARGV.size > 0 
		file = File.new( ARGV[0] )
		doc = REXML::Document.new(file)
		$dummy = true
	else	
		system("sudo /sbin/mdev -s")
		xmlstr = ""
		IO.popen("sudo /usr/sbin/lshw-static -xml") { |x|
			while x.gets
				xmlstr = xmlstr +$_
			end
		}
		doc = REXML::Document.new(xmlstr)
	end
	return doc
end

def get_mount_point(dev)
	return "/media/disk/" + dev.gsub("/dev/", "").gsub("/", "_")
end

def error_dialog(message)
	dialog = Gtk::MessageDialog.new($main_application_window, 
			Gtk::Dialog::MODAL,
			Gtk::MessageDialog::ERROR,
			Gtk::MessageDialog::BUTTONS_CLOSE,
			message)
	dialog.run
	dialog.destroy
end

def pwdialog
	dialog = Gtk::Dialog.new(
		extract_lang_string("pw_title"),
		nil,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL ],
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_OK
	question  = Gtk::Label.new(extract_lang_string("pw_desc"))
	question.height_request = 32
	entry_label = Gtk::Label.new(extract_lang_string("pw_password"))

	pass = Gtk::Entry.new
	pass.visibility = false
	pass.signal_connect('activate') {
		#puts pass.text
		dialog.response(Gtk::Dialog::RESPONSE_OK)
		# dialog.destroy
	}
	hbox = Gtk::HBox.new(false, 5)
	hbox.pack_start_defaults(entry_label)
	hbox.pack_start_defaults(pass)
	dialog.vbox.add(question)
	dialog.vbox.add(hbox)
	dialog.show_all
	success = false
	dialog.run do |response|
		 if response == Gtk::Dialog::RESPONSE_OK
			$password = pass.text
			$dialog_success = true
		end
		# return success, pass.text
		dialog.destroy
	end
end

def mount(partinfo, rw)
	laxsudo = system("check_lax_sudo")
	if laxsudo == false
		pwdialog
		password = $password if $dialog_success == true
		$password = nil
		return false if $dialog_success == false
		$dialog_success = false
	end
	puts "---"
	puts partinfo
	puts rw
	mount_opts = "-o noexec,nodev,nosuid,gid=1000,uid=1000"
	fstype = ""
	if partinfo[1] =~ /^ext/
		fstype = "-t ext4"
		mount_opts = "-o noexec,nodev,nosuid"
	elsif partinfo[1] =~ /^fat/
		fstype = "-t vfat"
		mount_opts = "-o noexec,nodev,nosuid,gid=1000,uid=1000,iocharset=utf8"
	elsif partinfo[1] == "iso9660"	
		# fstype = "-t iso9660"
		fstype = ""
		mount_opts = "-o noexec,nodev,nosuid,gid=1000,uid=1000,iocharset=utf8"
	elsif partinfo[1] == "ntfs"
		if system("which ntfs-3g")
			fstype = "-t ntfs-3g"
		else
			fstype = "-t ntfs"
		end
		mount_opts = "-o noexec,nodev,nosuid,gid=1000,uid=1000,utf8"
	else
		mount_opts = "-o noexec,nodev,nosuid"
	end
	unless rw == true
		mount_opts = mount_opts + ",ro"
	end
	mountdir = get_mount_point(partinfo[0])
	mountdir = partinfo[3] unless partinfo[3].nil?
	if laxsudo == true
		mkdir = "sudo /bin/mkdir -p " + mountdir
		mount = "sudo /bin/mount "  + fstype + " " + mount_opts + " " + partinfo[0] + " " + mountdir
	else
		mkdir = "echo '" + password + "' | sudo -S /bin/mkdir -p " + mountdir
		mount = "echo '" + password + "' | sudo -S /bin/mount "  + fstype + " " + mount_opts + " " + partinfo[0] + " " + mountdir
	end
	if $dummy == true
		puts mkdir
		puts mount
		puts "---"
		return true
	else
		puts "---"
		system(mkdir)
		if system(mount) 
			return true
		else
			return false
		end
	end
	return true
end

def umount(partinfo)
	puts "---"
	puts partinfo
	umount = "sudo /bin/umount " + partinfo[0]
	# eject = "sudo eject " + partinfo[0]  if partinfo[0] =~ /^\/dev\/sr/ 
	if $dummy == true
		puts umount
		puts "---"
		return true
	else	
		umount_success = system(umount)
		# system("sudo /sbin/eject " + partinfo[0]) if partinfo[0] =~ /^\/dev\/sr/
		puts "---"
		return true if umount_success == true
	end
	return false
end

def scan_parts (doc)
	alldisks = []
	doc.elements.each("//node[@class='storage']") { |x|
		par_product = ""
		par_vendor = ""
		begin
			par_product = x.elements["product"].text.to_s.strip
			par_vendor = x.elements["vendor"].text.to_s.strip
		rescue
		end
		begin
			businfo = x.elements["businfo"].text.to_s
		rescue
			businfo = "unknown"
		end
		x.elements.each("node[@class='disk']") { |element|
			parts = []
			product = ""
			size = 0
			unit = ""
			cdrom = false
			begin
				product = element.elements["product"].text.to_s
			rescue
				product = element.elements["description"].text.to_s
				product = par_vendor + " " + par_product unless par_vendor.strip == "" && par_product.strip == "" 
			end
			begin
				size = element.elements["size"].text.to_i
				unit = element.elements["size"].attributes["units"]
			rescue
			end
			# puts element.attributes["handle"]  + " " + product + " " + businfo + " " + size.to_s + " " + unit
			if element.attributes["id"] =~ /^cdrom/ 
				#	puts "  " + element.elements["logicalname"].text
				cdrom = true
				mount_point = nil
				log_name = []
				element.elements.each("logicalname") { |l| log_name.push(l.text) unless ( l.text.strip =~ /^\/dev\/scd/ || l.text.strip =~ /^\/dev\/cd/ || l.text.strip =~  /^\/dev\/dvd/  ) }
				state = "clear"
				if log_name.size > 1
					mount_point = log_name[1] 
					state = "mounted"
				end
				parts.push( [ log_name[0], "iso9660", state, mount_point, false ] )
			end
			element.elements.each("node[@class='volume']") { |n|
				state = ""
				mount_options = []
				rw = false
				begin
					puts "Checking: " + n.elements["logicalname"].text
					state = n.elements["configuration/setting[@id='state']"].attributes["value"].to_s
					mount_options = n.elements["configuration/setting[@id='mount.options']"].
						attributes["value"].to_s.split(",")
					mount_options.each { |m| rw = true if m == "rw" }
				rescue
				end
				fstype = nil
				begin
					fstype = n.elements["configuration/setting[@id='filesystem']"].attributes["value"].strip
				rescue
					fstype = "???"
				end
				is_extended = false
				begin
					is_extended = true if n.elements["capabilities/capability[@id='partitioned:extended']"].text.strip == "Extended partition"
				rescue
				end
				unless fstype == "swap" || is_extended == true
					# puts "  " + n.attributes["id"] + " " + n.elements["logicalname"].text + " " + 
					#	n.elements["configuration/setting[@id='filesystem']"].attributes["value"] + " " + state
					mount_point = nil
					log_name = []
					n.elements.each("logicalname") { |l| log_name.push(l.text) unless ( l.text.strip =~ /^\/dev\/scd/ || l.text.strip =~ /^\/dev\/cdrom/ ) }
					mount_point = log_name[1] if log_name.size > 1
					begin
						parts.push( [ n.elements["logicalname"].text.to_s,
						fstype.to_s,
						state, mount_point, rw ] )
					rescue
						puts "Ignore partition with missing logical name - probably lshw detected the EFI boot image"
						# parts.push( [ "/dev/null" , fstype.to_s, state, mount_point, rw ] )
					end
				end
				if is_extended == true
					n.elements.each("node[@class='volume']") { |m|
						begin
							istate = ""
							imount_options = []
							irw = false
							begin
								istate = m.elements["configuration/setting[@id='state']"].attributes["value"].to_s
								imount_options = m.elements["configuration/setting[@id='mount.options']"].
									attributes["value"].to_s.split(",")
								imount_options.each { |o| irw = true if o == "rw" }
							rescue
							end
							ifstype = nil
							begin
								ifstype = m.elements["configuration/setting[@id='filesystem']"].attributes["value"].strip
							rescue
								ifstype = "???"
								m.elements.each("description") { |d|
									puts "Checking: " + d.text
									ifstype = "fat" if d.text =~ /FAT/
									ifstype = "ntfs" if d.text =~ /NTFS/
 									ifstype = "ext3" if d.text =~ /Linux/
									if d.text =~ /swap/
										ifstype = "swap"
										fstype = "swap"
									end
								}
							end
							unless fstype == "swap"
								mount_point = nil
								log_name = []
								m.elements.each("logicalname") { |l| log_name.push(l.text) unless ( l.text.strip =~ /^\/dev\/scd/ || l.text.strip =~ /^\/dev\/cdrom/ ) }
								mount_point = log_name[1] if log_name.size > 1
								parts.push( [ m.elements["logicalname"].text,
								ifstype.to_s,
								istate, mount_point, rw ] )
							end
						rescue
						end
					}
				end
				
			}
			alldisks.push( [  businfo, product, size, unit, cdrom, parts ] )
		}
		# FIXME: This is weird copy&paste
		x.elements.each("node[@class='disk']/node[@class='disk']") { |element|
			parts = []
			product = ""
			size = 0
			unit = ""
			cdrom = false
			begin
				product = element.elements["product"].text.to_s
			rescue
				# product = element.elements["description"].text.to_s
				product = "unknown"
				product = par_vendor + " " + par_product unless par_vendor.strip == "" && par_product.strip == "" 
			end
			begin
				size = element.elements["size"].text.to_i
				unit = element.elements["size"].attributes["units"]
			rescue
			end
			# puts element.attributes["handle"]  + " " + product + " " + businfo + " " + size.to_s + " " + unit
			if element.attributes["id"] =~ /^cdrom/ 
				#	puts "  " + element.elements["logicalname"].text
				cdrom = true
				mount_point = nil
				log_name = []
				element.elements.each("logicalname") { |l| log_name.push(l.text) unless ( l.text.strip =~ /^\/dev\/scd/ || l.text.strip =~ /^\/dev\/cdrom/ ) }
				state = "clear"
				if log_name.size > 1
					mount_point = log_name[1] 
					state = "mounted"
				end
				parts.push( [ log_name[0], "iso9660", state, mount_point, false ] )
			end
			element.elements.each("node[@class='volume']") { |n|
				state = ""
				mount_options = []
				rw = false
				begin
					puts "Checking: " + n.elements["logicalname"].text
					state = n.elements["configuration/setting[@id='state']"].attributes["value"].to_s
					mount_options = n.elements["configuration/setting[@id='mount.options']"].
						attributes["value"].to_s.split(",")
					mount_options.each { |m| rw = true if m == "rw" }
				rescue
				end
				fstype = nil
				begin
					fstype = n.elements["configuration/setting[@id='filesystem']"].attributes["value"].strip
				rescue
					fstype = "???"
				end
				is_extended = false
				begin
					is_extended = true if n.elements["capabilities/capability[@id='partitioned:extended']"].text.strip == "Extended partition"
				rescue
				end
				unless fstype == "swap" || is_extended == true
					# puts "  " + n.attributes["id"] + " " + n.elements["logicalname"].text + " " + 
					#	n.elements["configuration/setting[@id='filesystem']"].attributes["value"] + " " + state
					mount_point = nil
					log_name = []
					n.elements.each("logicalname") { |l| log_name.push(l.text) unless ( l.text.strip =~ /^\/dev\/scd/ || l.text.strip =~ /^\/dev\/cdrom/ || l.text.strip =~ /^\/dev\/cdrw/ || l.text.strip =~ /^\/dev\/dvdrw/  ) }
					mount_point = log_name[1] if log_name.size > 1
					begin
						parts.push( [ n.elements["logicalname"].text,
						fstype.to_s,
						state, mount_point, rw ] )
					rescue
					end
				end
				if is_extended == true
					n.elements.each("node[@class='volume']") { |m|
						begin
							istate = ""
							imount_options = []
							irw = false
							begin
								istate = m.elements["configuration/setting[@id='state']"].attributes["value"].to_s
								imount_options = m.elements["configuration/setting[@id='mount.options']"].
									attributes["value"].to_s.split(",")
								imount_options.each { |o| irw = true if o == "rw" }
							rescue
							end
							ifstype = nil
							begin
								ifstype = m.elements["configuration/setting[@id='filesystem']"].attributes["value"].strip
							rescue
								ifstype = "???"
							end
							unless fstype == "swap"
								mount_point = nil
								log_name = []
								m.elements.each("logicalname") { |l| log_name.push(l.text) unless ( l.text.strip =~ /^\/dev\/scd/ || l.text.strip =~ /^\/dev\/cdrom/ ) }
								mount_point = log_name[1] if log_name.size > 1
								parts.push( [ m.elements["logicalname"].text,
								ifstype.to_s,
								istate, mount_point, rw ] )
							end
						rescue
						end
					}
				end
				
			}
			alldisks.push( [  businfo, product, size, unit, cdrom, parts ] )
		}
		x.elements.each("node[@class='volume']") { |element|
			if element.elements["logicalname"].text =~ /^\/dev\/sd/ && businfo =~ /^usb/
				parts = []
				product = ""
				size = 0
				unit = ""
				cdrom = false
				istate = ""
				imount_options = []
				irw = false
				begin
					istate = element.elements["configuration/setting[@id='state']"].attributes["value"].to_s
					imount_options = element.elements["configuration/setting[@id='mount.options']"].
					attributes["value"].to_s.split(",")
					imount_options.each { |o| irw = true if o == "rw" }
				rescue
				end
				ifstype = nil
				begin
					ifstype = element.elements["configuration/setting[@id='filesystem']"].attributes["value"].strip
				rescue
					ifstype = "???"
				end
				# udrive = UsbDrive.new(element.elements["logicalname"].text)
				begin
					product = x.elements["vendor"].text + " " + x.elements["product"].text
				#	udrive.product = x.elements["product"].text
				rescue
					product = par_vendor + " " + par_product unless par_vendor.strip == "" && par_product.strip == "" 
				end
				mount_point = nil
				log_name = []
				size = element.elements["size"].text.to_i
				element.elements.each("logicalname") { |l| log_name.push(l.text) unless ( l.text.strip =~ /^\/dev\/scd/ || l.text.strip =~ /^\/dev\/cdrom/ ) }
				mount_point = log_name[1] if log_name.size > 1
				parts.push( [ element.elements["logicalname"].text, ifstype.to_s, istate, mount_point, irw ] )
			end
			alldisks.push( [  businfo, product, size, unit, cdrom, parts ] )
			#all_drives[element.elements["logicalname"].text] = udrive unless 
			#all_drives.has_key?( element.elements["logicalname"].text )
		}
	}
	return alldisks
end

def scan_parted 
	ENV['LC_ALL'] = "C"
	alldisks = Array.new
	"a".upto("z") { |j|
		parts = Array.new
		model = nil
		size = 0
		IO.popen("sudo parted -s /dev/sd" + j + " unit B print") { |l|
			partype = nil
			while l.gets
				# puts $_
				if $_ =~ /^Disk /
					size = $_.strip.split[-1].gsub("B", "").to_i
					puts size.to_s
				end
				if $_ =~ /^Model: /
					model = $_[6..-1].gsub("(scsi)", "").strip
					puts model
				end
				if $_ =~ /^Partition Table: loop/ 
					parttype = "superfloppy"
				elsif $_ =~ /^Partition Table: msdos/ 
					parttype = "msdos"
				elsif $_ =~ /^Partition Table: gpt/ 
					parttype = "gpt"
				end
				if $_ =~ /^Number/ && parttype == "msdos"
					line = $_.chomp
					# puts line
					nstart = $_.index("Number")
					sstart = $_.index("Start")
					estart = $_.index("End")
					bstart = $_.index("Size")
					fstart = $_.index("File system")
					zstart =  $_.index("Flags")
					fend = $_.index("Flags") - 1
				elsif
					$_ =~ /^Number/ && parttype == "gpt"
					nstart = $_.index("Number")
					sstart = $_.index("Start")
					estart = $_.index("End")
					bstart = $_.index("Size")
					fstart = $_.index("File system")
					dstart = $_.index("Name")
					zstart =  $_.index("Flags")
					fend = $_.index("Name") - 1
				end
				unless $_.strip == "" || nstart.nil?
					# puts $_
					pnum = $_[0.. sstart-1].strip.to_i
					psize = $_[bstart .. fstart-1].strip.gsub("B", "").to_i
					fsyst = $_[fstart .. fend]
					# puts pnum.to_s
					unless fsyst.nil? || fsyst.strip.to_s == "" || pnum.to_i < 1
						mounted = "clean"
						readwrite = false
						mountpoint = nil
						if pnum > 0 && ( parttype == "msdos" || parttype == "gpt")
							device =  "/dev/sd" + j + pnum.to_s
						elsif pnum > 0
							device =  "/dev/sd" + j
						end
						puts device + " " + psize.to_s + " " + fsyst.strip
						IO.popen("mount") { |m|
							while m.gets
								mtoks = $_.strip.split
								if mtoks[0].strip == device
									mounted = "mounted"
									mountpoint = mtoks[2].strip
									mountmodes = mtoks[-1].gsub(/\(|\)/, "").split(",")
									readwrite = true if mountmodes.include?("rw")
									# puts "read-write" if mountmodes.include?("rw")
								end
							end
						}
						parts.push( [ device, fsyst.strip, mounted, mountpoint, readwrite ] )
					end
				end
			end
		}
		if parts.size > 0
			alldisks.push( [ "unknown", model, size, "", false, parts ] )
		end
	}
	0.upto(9) { |j|
		if system("test -b /dev/sr" + j.to_s )
			mounted = "clean"
			mountpoint = nil
			IO.popen("mount") { |m|
				while m.gets
					mtoks = $_.strip.split
					if mtoks[0].strip == "/dev/sr" + j.to_s
						mounted = "mounted"
						mountpoint = mtoks[2].strip
					end
				end
			}
			parts = Array.new
			parts.push([ "/dev/sr" + j.to_s, "iso9660", mounted, mountpoint, false ])
			alldisks.push( [ "unknown", "CD/DVD", 0, "", true, parts ] )
			size = 0
		end
	}
	return alldisks
end

def build_panel(alldisks)
	outer_vbox = Gtk::VBox.new(false, 1)
	fat_font = Pango::FontDescription.new("Sans Bold")
	alldisks.each { |d|
		if d[5].size > 0
			text = d[1]
			if d[0] =~ /^usb/ 
				# text = extract_lang_string("pan_usbdrive")
				# text = text + "(" + d[1] + ")" unless d[1].to_s.strip == ""
				busdesc = "USB"
			elsif d[0] =~ /^unknown/
				busdesc = ""
			else
				busdesc = "IDE/SATA"
			end
			if d[2] > 0
				if d[2] > 6000000000
					text = text  + " (" + ( d[2] / 1024 / 1024 / 1024).to_i.to_s + " GB) " + busdesc
				elsif d[2] > 6000000
					text = text  + " (" + ( d[2] / 1024 / 1024).to_i.to_s + " MB) " + busdesc
				else
					text = text + " (" + d[2].to_s + " B) " + busdesc
				end
			else
				text = text + " " + busdesc
			end
			l = Gtk::Label.new(text)
			l.modify_font(fat_font)
			icon_theme = Gtk::IconTheme.default
			inner_hbox = Gtk::HBox.new(false, 1)
			inner_vbox = Gtk::VBox.new(false, 1)
			l.set_alignment(0,0.5)
			begin
				if d[4] == true
					pixbuf = icon_theme.load_icon("gnome-dev-dvd", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK)
				elsif d[0] =~ /^usb/
					pixbuf = icon_theme.load_icon("gnome-dev-media-sdmmc", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK)
				else
					pixbuf = icon_theme.load_icon("gnome-dev-harddisk", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK)
				end
				img = Gtk::Image.new(pixbuf)
				img.set_alignment(0,0.5)
				inner_hbox.pack_start(img, false, false, 0)
			rescue
				$stderr.puts "Loading icons failed"
			end
			inner_vbox.pack_start(l, false, false, 0)
			d[5].each { |p|
				dev_desc = "???"
				if p[0] =~ /^\/dev\/sd[a-z]$/ 
					dev_desc = extract_lang_string("pan_stick")
				elsif p[0] =~ /^\/dev\/sd[a-z][0-9]$/
					part_num = p[0].split(/\/dev\/sd[a-z]/)
					dev_desc = extract_lang_string("pan_part") + " " + part_num[1].to_s
				elsif p[0] =~ /^\/dev\/sr[0-9]$/ || p[0] =~ /^\/dev\/scd[0-9]$/ || p[0] =~ /^\/dev\/cdrom/ 
					dev_desc = extract_lang_string("pan_optical")
				end
				writeable = Gtk::CheckButton.new(extract_lang_string "pan_writable")
				dev_details = dev_desc + " (" + p[0].to_s.gsub("/dev/", "") + ", " + p[1].to_s + ")"
				# mount_button = Gtk::Button.new(dev_desc + " (" + p[0].gsub("/dev/", "") + ", " + p[1] + ") einbinden" )
				mount_button = Gtk::Button.new(extract_lang_string("pan_layout").gsub("%ACTION%", extract_lang_string("pan_mount")).gsub("%DRIVE%", dev_details)) 
				mount_button.width_request = 260
				mount_button.height_request = 32
				show_button = Gtk::Button.new(extract_lang_string("pan_show"))
				show_button.width_request = 120
				show_button.height_request = 32
				writeable.active = p[4]
				if d[4] == true
					writeable.sensitive = false
				end
				unless p[2] == "mounted"
					show_button.sensitive = false
				else
					writeable.sensitive = false
					if p[3].strip.to_s =~ /^\/lesslinux\// 
						mount_button.label = extract_lang_string("pan_sysdrive")
						mount_button.sensitive = false
					else
						mount_button.label = extract_lang_string("pan_layout").gsub("%ACTION%", extract_lang_string("pan_umount")).gsub("%DRIVE%", dev_details)
						# dev_desc + " (" + p[0].gsub("/dev/", "") + ", " + p[1] + ") freigeben"
					end
				end
				if p[1] =~  /luks/i 
					mount_button.sensitive = false
					show_button.sensitive = false
				end
				show_button.signal_connect( "clicked" ) { |w|
					if p[3].nil?
						system("Thunar " + get_mount_point(p[0]))
					else
						system("Thunar " + p[3])
					end
				}
				mount_button.signal_connect( "clicked" ) {|w|
					unless p[2] == "mounted"
						mount_res = mount(p, writeable.active?)
						if mount_res == true
							writeable.sensitive = false
							show_button.sensitive = true
							mount_button.label = extract_lang_string("pan_layout").gsub("%ACTION%", extract_lang_string("pan_umount")).gsub("%DRIVE%", dev_details)
							p[2] = "mounted"
							if p[3].nil?
								system("Thunar " + get_mount_point(p[0]))
							else
								system("Thunar " + p[3])
							end
						else
							error_dialog(extract_lang_string("pan_mount_error"))
						end
					else
						umount_res = umount(p)
						if umount_res == true
							writeable.sensitive = true unless d[4] == true
							show_button.sensitive = false
							mount_button.label = extract_lang_string("pan_layout").gsub("%ACTION%", extract_lang_string("pan_mount")).gsub("%DRIVE%", dev_details)
							p[2] = "clean"
						else
							error_dialog(extract_lang_string("pan_umount_error"))
						end
					end
				}
				button_box = Gtk::HBox.new(false, 1)
				button_box.pack_start(writeable, false, false, 2)
				button_box.pack_start(mount_button, false, false, 2)
				button_box.pack_start(show_button, false, false, 2)
				inner_vbox.pack_start(button_box, false, false, 2)
			}
			inner_hbox.pack_start(inner_vbox, false, false, 5)
			outer_vbox.pack_start(inner_hbox, false, false, 5)
			sep = Gtk::HSeparator.new
			outer_vbox.pack_start(sep)
		end
	}
	return outer_vbox
end

doc = read_devs
alldisks = scan_parts(doc)
alldisks = scan_parted if alldisks.size < 1 
outer_vbox = build_panel(alldisks)

window = Gtk::Window.new(Gtk::Window::TOPLEVEL)
window.set_title(extract_lang_string("win_title"))
window.border_width = 10
window.set_size_request(600, 400)
# window.set_size_request(240, 240)
window.signal_connect('delete_event') { 
	# cleanup
	Gtk.main_quit 
}

scroll_pane = Gtk::ScrolledWindow.new
scroll_pane.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)

reread = Gtk::Button.new("Neu einlesen")
reread.height_request = 32
layout_box = Gtk::VBox.new(false, 0)
scroll_pane.add_with_viewport(outer_vbox)
layout_box.pack_start(scroll_pane, true, true, 0)
# layout_box.pack_start(reread, false, false, 0)
window.add(layout_box)
window.show_all
Gtk.main



