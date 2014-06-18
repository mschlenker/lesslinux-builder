#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
require "rexml/document"

# License? GPL v2.0

#LANGUAGE = ENV['LANGUAGE'][0..1]

LANGUAGE = ENV['LANGUAGE'][0..1]

#@xbranding = File.new( "/etc/lesslinux/branding/branding.xml" )
#@branding = REXML::Document.new  @xbranding

LOCSTRINGS = {
	"de" => {
		"unknown_fs" => "Unbekanntes Dateisystem",
		"fin_title" => "MBR neu geschrieben",
		"fin_label" => "Das Schreiben des Bootsektors ist abgeschlossen!",
		"fin_error" => "Fehler beim Schreiben",
		"fin_error_desc" => "Der Bootsektor konnte nicht geschrieben werden. Drücken Sie \"OK\", um es mit geänderten Einstellungen erneut zu probieren oder \"Abbrechen\" um den Assistenten zu beenden!",
		"assi_desc" => "Dieser Assistent hilft Ihnen bei Windows-Startproblemen, die durch ein versehentliches Löschen des Startsektors entstanden sind.",
		"assi_title" => "Startsektor neu schreiben",
		"select_label" => "Wählen Sie die Festplatte oder das USB-Laufwerk, auf dem Sie den Bootsektor neu schreiben wollen. Es werden nur Festplatten angezeigt, die nicht eingebunden sind!",
		"mbr_label" => "Wählen Sie die den Typ des Bootloaders, den Sie schreiben wollen.",
		"dropdown_auto" => "automatisch auswählen (nicht empfohlen)",
		"dropdown_zero" => "Start von diesem Laufwerk deaktivieren",
		"force" => "Schreiben erzwingen?",
		"drive" => "Auswahl des Laufwerkes",
		"do_you_want" => "Wollen Sie den Bootsektor mit den vorgenommenen Einstellungen schreiben?",
		"disclaimer" => "<b>Haftungsausschluß:</b> Ich bin mir bewußt, dass das Schreiben eines Bootsektors auf die falsche Festplatte Startprobleme oder Datenverlust verursachen kann. Die vorgenommenen Einstellungen habe ich überprüft.",
		"overview" => "Zusammenfassung",
		"prog_title" => "Startsektor neu schreiben",
		"ovlabel" => "<b>Bootsektor schreiben auf:</b> %TARGET%\n\n<b>Ausgewählter Typ:</b> %TYPE%\n\n<b>Schreiben erzwingen?</b> %FORCE%",
		"yes" => "ja",
		"no" => "nein"
	},
	"en" => {
		"unknown_fs" => "Unknown file system",
		"fin_title" => "MBR written",
		"fin_label" => "Writing the MBR is finished!",
		"fin_error" => "Error writing MBR",
		"fin_error_desc" => "Writing the boot sector failed. Press \"OK\", to try again with different settings or \"Cancel\" to quit the program!",
		"assi_desc" => "This program solves Windows startup trouble that was caused by accidentally deleting or overwriting the master boot record (MBR).",
		"assi_title" => "Restore master boot record",
		"select_label" => "Select the hard disk or thumb drive on which you want to restore the boot sector. Just drives that are currently not mounted are shown.",
		"mbr_label" => "Select the type of master boot record that you want to write.",
		"dropdown_auto" => "select automatically (not recommended)",
		"dropdown_zero" => "disable boot from this disk",
		"force" => "Force writing?",
		"drive" => "Select target drive",
		"do_you_want" => "Do you want to write the master boot record with the selected settings?",
		"disclaimer" => "<b>Disclaimer:</b> I am aware of the fact that the wrong selection of target drive or type of MBR may cause boot problems or loss of data. Therefore I carefully checked the settings made.",
		"overview" => "Overview",
		"prog_title" => "Restore master boot record",
		"ovlabel" => "<b>Write master boot record to:</b> %TARGET%\n\n<b>Selected Type:</b> %TYPE%\n\n<b>Force writing?</b> %FORCE%",
		"yes" => "yes",
		"no" => "no"
	},
	"pl" => {
		 "unknown_fs" => "Nieznany system plików",
                "fin_title" => "MBR zapisany",
                "fin_label" => "Zakończono zapis MBR!",
                "fin_error" => "Błąd zapisu MBR",
                "fin_error_desc" => "Zapis MBR nie powiódł się. Kliknij \"OK\" aby spróbować ponownie z innymi ustawieniami lub \"Anuluj\" aby zakończyć program!",
                "assi_desc" => "Program ten rozwiązuje problemy z uruchomieniem Windows spowodowane uszkodzeniem lub nadpisaniem głównego rekordu startowego (MBR).",
                "assi_title" => "Przywróć MBR",
                "select_label" => "Wybierz dysk twardy lub pendrive któego MBR chcesz przywrócić. Lista zawiera wyłacznie niezamontowane napędy.",
                "mbr_label" => "Select the type of master boot record that you want to write.",
                "dropdown_auto" => "wybierz automatycznie (nie zalecane)",
                "dropdown_zero" => "wyłącz rozruch z tego dysku",
                "force" => "Wymusić zapis?",
                "drive" => "Wybierz napęd doecelowy",
                "do_you_want" => "Czy chcesz zapisać MBR z tymi ustawieniami?",
                "disclaimer" => "<b>Oświadczenie:</b> Jestem świadom, że niewłąściwy wybór dysku docelowego lub typu MBR może spowodować problem z uruchomieniem systemu lub utratę danych. Z tego względu dokładnie sprawdziłem wszystkie ustawienia.",
                "overview" => "Podsumowanie",
                "prog_title" => "Przywracanie MBR",
                "ovlabel" => "<b>Zapisz MBR na dysku:</b> %TARGET%\n\n<b>Typ MBR:</b> %TYPE%\n\n<b>Wymuszanie zapisu?</b> %FORCE%",
                "yes" => "tak",
                "no" => "nie"
	},
	"es" => {
		 "unknown_fs" => "Archivo de sistema desconocido",
                "fin_title" => "MBR escrito",
                "fin_label" => "La escritura del MBR ha terminado",
                "fin_error" => "Error al escribir el MBR",
                "fin_error_desc" => "La escritura en el sector de arranque ha fallado. Presione \"OK\", para intentarlo de nuevo con una diferente configuración o \"Cancel\" para salir del programa",
                "assi_desc" => "Este programa resuelve los problemas de inicio de Windows provocados por un borrado accidental o al sobreescribir el MBR.",
                "assi_title" => "Restaurar el MBR",
                "select_label" => "Seleccionar el disco duro o unidad flash en la que desea restaurar el sector de arranque. Sólo se mostrarán las unidades que están libres.",
                "mbr_label" => "Seleccione el tipo de MBR que desea escribir.",
                "dropdown_auto" => "Selección automática (no recomendada)",
                "dropdown_zero" => "Desactivar arranque de este disco",
                "force" => "¿Forzar escritura?",
                "drive" => "Seleccionar la unidad de destino",
                "do_you_want" => "¿Desea escribir el MBR con la configuración seleccionada?",
                "disclaimer" => "<b>Exención de responsabilidad:</b> Soy consciente de que una selección equivocada de la unidad de destino o del tipo de MBR puede causar problemas de inicio o pérdida de datos. Por tanto, debo tener cuidado con los ajustes realizados.",
                "overview" => "Información general",
                "prog_title" => "Restaurar MBR",
                "ovlabel" => "<b>Escribir MBR en:</b> %TARGET%\n\n<b>Seleccionar tipo:</b> %TYPE%\n\n<b>¿Forzar escritura?</b> %FORCE%",
                "yes" => "si",
                "no" => "no"
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

#@xbranding = File.new( "/etc/lesslinux/branding/branding.xml" )
#@branding = REXML::Document.new  @xbranding

assi = Gtk::Assistant.new
# assi.deletable = false

$dummy = false
alldisks = nil
partarray = []
diskarray = []
niceparts = []
nicedrives = []
partsizes = []
drivesizes = []
xml_read_count = 0

def read_devs
	xml_obj = nil
	if ARGV.size > 0 
		file = File.new( ARGV[0] )
		doc = REXML::Document.new(file)
		$dummy = true
	else	
		system("sudo /sbin/mdev -s")
		sleep 2
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

def scan_parts (doc)
	alldisks = []
	doc.elements.each("//node[@class='storage']") { |x|
		begin
			businfo = x.elements["businfo"].text.to_s
		rescue
			businfo = "unknown"
		end
		storageproduct = ""
		begin
			storageproduct = x.elements["vendor"].text.to_s + " " + x.elements["product"].text.to_s
		rescue
		end
		x.elements.each("node[@class='disk']") { |element|
			parts = []
			product = ""
			size = 0
			unit = ""
			cdrom = false
			diskname = element.elements["logicalname"].text.to_s
			begin
				product = element.elements["product"].text.to_s
			rescue
				product = element.elements["description"].text.to_s 
				product = storageproduct unless storageproduct == ""
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
				element.elements.each("logicalname") { |l| log_name.push(l.text) }
				state = "clear"
				if log_name.size > 1
					mount_point = log_name[1] 
					state = "mounted"
				end
				parts.push( [ element.elements["logicalname"].text, "iso9660", state, mount_point, false, 0 ] )
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
					fstype = n.elements["logicalname"].text
				end
				is_extended = false
				begin
					is_extended = true if n.elements["capabilities/capability[@id='partitioned:extended']"].text.strip == "Extended partition"
				rescue
				end
				unless  is_extended == true # || fstype == "swap"
					# puts "  " + n.attributes["id"] + " " + n.elements["logicalname"].text + " " + 
					#	n.elements["configuration/setting[@id='filesystem']"].attributes["value"] + " " + state
					mount_point = nil
					log_name = []
					capacity = 0
					begin
						capacity = n.elements["capacity"].text.to_i
					rescue
					end
					n.elements.each("logicalname") { |l| log_name.push(l.text) }
					mount_point = log_name[1] if log_name.size > 1
					parts.push( [ n.elements["logicalname"].text,
					fstype.to_s,
					state, mount_point, rw, capacity ] )
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
								ifstype = "unbekanntes Dateisystem"
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
								capacity = 0
								begin
									capacity = m.elements["capacity"].text.to_i
								rescue
								end
								m.elements.each("logicalname") { |l| log_name.push(l.text) }
								mount_point = log_name[1] if log_name.size > 1
								parts.push( [ m.elements["logicalname"].text,
								ifstype.to_s,
								istate, mount_point, rw, capacity ] )
							end
						rescue
						end
					}
				end
				
			}
			alldisks.push( [  businfo, product, size, unit, cdrom, parts, diskname ] )
		}
		# FIXME: This is weird copy&paste
		x.elements.each("node[@class='disk']/node[@class='disk']") { |element|
			parts = []
			product = ""
			size = 0
			unit = ""
			cdrom = false
			diskname = element.elements["logicalname"].text.to_s
			begin
				product = element.elements["product"].text.to_s
			rescue
				# product = element.elements["description"].text.to_s
				product = "unknown"
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
				element.elements.each("logicalname") { |l| log_name.push(l.text) }
				state = "clear"
				if log_name.size > 1
					mount_point = log_name[1] 
					state = "mounted"
				end
				parts.push( [ element.elements["logicalname"].text, "iso9660", state, mount_point, false, 0 ] )
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
					fstype = extract_lang_string("unknown_fs")
				end
				is_extended = false
				begin
					is_extended = true if n.elements["capabilities/capability[@id='partitioned:extended']"].text.strip == "Extended partition"
				rescue
				end
				unless is_extended == true # || fstype == "swap" 
					# puts "  " + n.attributes["id"] + " " + n.elements["logicalname"].text + " " + 
					#	n.elements["configuration/setting[@id='filesystem']"].attributes["value"] + " " + state
					mount_point = nil
					log_name = []
					capacity = 0
					begin
						capacity = n.elements["capacity"].text.to_i
					rescue
					end
					n.elements.each("logicalname") { |l| log_name.push(l.text) }
					mount_point = log_name[1] if log_name.size > 1
					parts.push( [ n.elements["logicalname"].text,
					fstype.to_s,
					state, mount_point, rw, capacity ] )
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
								ifstype = extract_lang_string("unknown_fs")
							end
							# unless fstype == "swap"
							mount_point = nil
							log_name = []
							capacity = 0
							begin
								capacity = m.elements["capacity"].text.to_i
							rescue
							end
							m.elements.each("logicalname") { |l| log_name.push(l.text) }
							mount_point = log_name[1] if log_name.size > 1
							parts.push( [ m.elements["logicalname"].text,
							ifstype.to_s,
							istate, mount_point, rw, capacity ] )
							# end
						rescue
						end
					}
				end
				
			}
			alldisks.push( [  businfo, product, size, unit, cdrom, parts, diskname ] )
		}
		x.elements.each("node[@class='volume']") { |element|
			if element.elements["logicalname"].text =~ /^\/dev\/sd/ && businfo =~ /^usb/
				diskname = element.elements["logicalname"].text.to_s
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
					ifstype = extract_lang_string("unknown_fs")
				end
				# udrive = UsbDrive.new(element.elements["logicalname"].text)
				begin
					product = x.elements["vendor"].text + " " + x.elements["product"].text
				#	udrive.product = x.elements["product"].text
				rescue
				end
				mount_point = nil
				log_name = []
				size = element.elements["size"].text.to_i
				capacity = 0
				begin
					capacity = m.elements["capacity"].text.to_i
				rescue
				end
				element.elements.each("logicalname") { |l| log_name.push(l.text) }
				mount_point = log_name[1] if log_name.size > 1
				parts.push( [ element.elements["logicalname"].text, ifstype.to_s, istate, mount_point, irw, capacity ] )
				alldisks.push( [  businfo, product, size, unit, cdrom, parts, diskname ] )
			end
			#all_drives[element.elements["logicalname"].text] = udrive unless 
			#all_drives.has_key?( element.elements["logicalname"].text )
		}
	}
	return alldisks
end

def update_partcombo(disks, partcombo, partrows, drivecombo, driverows)
	(partrows - 1).downto(0) { |i| 
		puts "removing " + i.to_s
		partcombo.remove_text(i)
	}
	(driverows - 1).downto(0) { |i| 
		puts "removing " + i.to_s
		drivecombo.remove_text(i)
	}
	part_array = []
	new_rows = 0
	disk_array = []
	disk_rows = 0
	niceparts = []
	nicedrives = []
	partsizes = []
	drivesizes = []
	disks.each { |d|
		sizestr = ""
		if d[2] > 7_900_000_000
			sizestr = ((d[2].to_f / 1073741824 ) + 0.5).to_i.to_s + "GB"
		else
			sizestr = (d[2].to_f / 1048576 ).to_i.to_s + "MB"
		end
		businfo = "IDE/SATA"
		businfo = "USB" if d[0] =~ /^usb/
		mounted = false
		d[5].each { |p|
			psize = ""
			if p[5] > 7_900_000_000
				psize = ((p[5].to_f / 1073741824 ) + 0.5).to_i.to_s + "GB"
			else
				psize = (p[5].to_f / 1048576 ).to_i.to_s + "MB"
			end
			unless p[2] == "mounted" || d[4] == true
				nicepart = d[1] + " (" + businfo + ", " + sizestr + ") Partition " + p[0] + " (" + p[1] + ", " + psize + ")"
				partcombo.append_text(nicepart)
				new_rows += 1
				part_array.push(p[0])
				niceparts.push(nicepart)
				partsizes.push(p[5])
			else
				mounted = true
			end
		}
		unless mounted == true || d[6].strip =~ /^\/dev\/sr/  
			begin
				device = d[6]
				nicedrive = d[1] + " " + device + " (" + businfo + ", " + sizestr + ")"
				drivecombo.append_text(nicedrive)
				disk_rows += 1
				disk_array.push(device)
				nicedrives.push(nicedrive)
				drivesizes.push(d[2])
			rescue
				puts "trouble processing " + d[5].join(" // ")
			end
		end
	}
	partcombo.active = 0
	drivecombo.active = 0
	return new_rows, part_array, disk_rows, disk_array, niceparts, nicedrives, partsizes, drivesizes
end



#========================================
# Core logic
#========================================

def apply_settings(device, mbr_type, force, assi)
	puts "Device to write MBR: " + device
	puts "Switches for MBR types: " + mbr_type
	puts "Force write? " + force.to_s
	command_line = "ms-sys " + mbr_type 
	command_line = command_line + " -f " if force == true
	command_line = command_line + " " + device
	puts command_line
	close_parent = false
	if system(command_line)
		puts "Write successful!"
		dialog = Gtk::Dialog.new(extract_lang_string("fin_title"),assi,Gtk::Dialog::MODAL,
			[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
		)
		dialog.has_separator = false
		label = Gtk::Label.new(extract_lang_string("fin_label"))
		label.wrap = true
		image = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
		hbox = Gtk::HBox.new(false, 5)
		hbox.border_width = 10
		hbox.pack_start_defaults(image);
		hbox.pack_start_defaults(label);
		dialog.vbox.add(hbox)
		dialog.show_all
		dialog.run
		dialog.destroy
		close_parent = true
	else
		puts "Write failed!"
		dialog = Gtk::Dialog.new(extract_lang_string("fin_error"),assi,Gtk::Dialog::MODAL,
			[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ],
			[ Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL ]
		)
		dialog.has_separator = false
		label = Gtk::Label.new(extract_lang_string("fin_error_desc"))
		label.wrap = true
		image = Gtk::Image.new(Gtk::Stock::DIALOG_ERROR, Gtk::IconSize::DIALOG)
		hbox = Gtk::HBox.new(false, 5)
		hbox.border_width = 10
		hbox.pack_start_defaults(image);
		hbox.pack_start_defaults(label);
		dialog.vbox.add(hbox)
		dialog.show_all
		dialog.run { |res|
			close_parent = true unless res == Gtk::Dialog::RESPONSE_OK
		}
		dialog.destroy
	end
	assi.destroy if close_parent == true
end

#========================================
# First window - tell the user what we do
#========================================

desclabel = Gtk::Label.new
desclabel.set_markup(extract_lang_string("assi_desc"))
desclabel.wrap = true
desclabel.width_request = 550
desclabel.xalign = 0.1

descpage = assi.append_page(desclabel)
assi.set_page_title(desclabel, extract_lang_string("assi_title") )
assi.set_page_type(desclabel, Gtk::Assistant::PAGE_CONTENT)
assi.set_page_complete(desclabel, true) # false)

#========================================
# Second window - choose the drive
#========================================

partbox = Gtk::VBox.new(false, 5)
partlabel = Gtk::Label.new
partlabel.set_markup(extract_lang_string("select_label"))
partlabel.wrap = true
partlabel.width_request = 550
partlabel.xalign = 0.1

# This is a dummy, it is never shown, here for compatibility reasons
partcombo = Gtk::ComboBox.new
partrows = 0
diskcombo = Gtk::ComboBox.new
diskrows = 0
diskcombo.sensitive = true
partbox.pack_start(partlabel, false, true, 5)
partbox.pack_start(diskcombo, false, true, 5)

typelabel = Gtk::Label.new
typelabel.set_markup(extract_lang_string("mbr_label"))
typelabel.wrap = true
typelabel.width_request = 550
typelabel.xalign = 0.1

typecombo = Gtk::ComboBox.new
mbr_types = [
	[ "-m", "Windows 2000/XP/2003" ],
	[ "-i", "Windows Vista" ],
	[ "-7", "Windows 7/8" ],
	[ "-s", "Syslinux Public Domain" ],
	[ "-w", extract_lang_string("dropdown_auto") ],
	[ "-z", extract_lang_string("dropdown_zero") ]
]
mbr_types.each { |t| typecombo.append_text(t[1]) }
typecombo.active = 0
forcecheck = Gtk::CheckButton.new(extract_lang_string("force"))
partbox.pack_start(typelabel, false, true, 5)
partbox.pack_start(typecombo, false, true, 5)
partbox.pack_start(forcecheck, false, true, 5)

partpage = assi.append_page(partbox)
assi.set_page_title(partbox, extract_lang_string("drive") )
assi.set_page_type(partbox, Gtk::Assistant::PAGE_CONTENT)
assi.set_page_complete(partbox, false)

#========================================
# Last window - confirm the settings
#========================================

lastlabel = Gtk::Label.new(extract_lang_string("do_you_want"))
lastlabel.wrap = true
lastlabel.width_request = 550
lastlabel.xalign = 0.1

ovlabel = Gtk::Label.new
ovlabel.wrap = true
ovlabel.width_request = 500
ovlabel.xalign = 0.3

lastdesc = Gtk::Label.new
lastdesc.set_markup(extract_lang_string("disclaimer"))
lastdesc.wrap = true
lastdesc.width_request = 500
lastdesc.xalign = 0.1
lastcheck = Gtk::CheckButton.new
lasthbox = Gtk::HBox.new(false, 5)
lasthbox.pack_start(lastcheck, false, true, 5)
lasthbox.pack_start(lastdesc, false, true, 5)

lastbox = Gtk::VBox.new(false, 5)
lastbox.pack_start(lastlabel, false, true, 5)
lastbox.pack_start(ovlabel, false, true, 5)
lastbox.pack_start(lasthbox, false, true, 5)

lastpage = assi.append_page(lastbox)
assi.set_page_title(lastbox, extract_lang_string("overview"))
assi.set_page_type(lastbox, Gtk::Assistant::PAGE_CONFIRM)
assi.set_page_complete(lastbox, false)

diskcombo.signal_connect('changed') {
	lastcheck.active = false
	assi.set_page_complete(lastbox, false)
}

typecombo.signal_connect('changed') {
	lastcheck.active = false
	assi.set_page_complete(lastbox, false)
}

lastcheck.signal_connect('clicked') { |b|
	if b.active? 
		assi.set_page_complete(lastbox, true)
	else
		assi.set_page_complete(lastbox, false)
	end
}

#========================================
# Common settings and callbacks
#========================================

assi.set_title  extract_lang_string("prog_title")
assi.border_width = 10
assi.set_size_request(600, 410)
assi.signal_connect('destroy') { Gtk.main_quit }
assi.signal_connect('cancel')  { assi.destroy }
assi.signal_connect('close')   { |w| 
	apply_settings(diskarray[diskcombo.active], mbr_types[typecombo.active][0], forcecheck.active?, assi)
	# w.destroy
}

assi.set_forward_page_func{|curr|
	scantypes = []
	scandev = diskarray[diskcombo.active]
	nicedev = nicedrives[diskcombo.active]
	scansize = drivesizes[diskcombo.active]
	forcewrite = extract_lang_string("no")
	forcewrite = extract_lang_string("yes") if forcecheck.active?
	# "<b>Bootsektor schreiben auf:</b> %TARGET%\n\n<b>Ausgewählter Typ:</b> %TYPE%\n\n<b>Schreiben erzwingen?</b> %FORCE%",
	ovlabel.set_markup(extract_lang_string("ovlabel").gsub("%TARGET%", nicedev.to_s).
		gsub("%TYPE%", mbr_types[typecombo.active][1]).gsub("%FORCE%", forcewrite))
	
	if curr == 0
		# when switching from first to second screen, read drivelist
		puts "current screen 0, rereading drivelist"
		alldisks = scan_parts(read_devs) if xml_read_count < 1
		xml_read_count += 1
		partrows, partarray, diskrows, diskarray, niceparts, nicedrives, partsizes, drivesizes = 
			update_partcombo(alldisks, partcombo, partrows, diskcombo, diskrows)
		if diskrows + partrows > 0
			assi.set_page_complete(partbox, true)
		else
			assi.set_page_complete(partbox, false)
		end
		# usbdrives = get_usbdrives_lshw
		# puts usbdrives
		# usable_drives = create_drivelist(choicebox, usable_drives.size, usbdrives)
		# assi.set_page_complete(choice_vbox, usable_drives.size > 0)
		1
	else
		curr + 1
	end
}

assi.show_all
Gtk.main
