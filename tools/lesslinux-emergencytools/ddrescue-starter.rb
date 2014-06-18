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
		"prog_title" => "Exakte Kopie von Festplatten",
		"unknown_fs" => "Unbekanntes Dateisystem",
		"no_part_found" => "Keine geeignete Quellpartition gefunden - ggf. Laufwerkseinbindungen lösen",
		"no_disk_found" => "Keine geeignete Quellfestplatte gefunden - ggf. Laufwerkseinbindungen lösen",
		"no_target_found" => "Kein geeignetes Ziellaufwerk vorhanden",
		"terminal_run" => "Bitweises Klonen %N%. Durchlauf - Bitte nicht schließen",
		"copy_fin_short" => "Kopieren abgeschlossen",
		"copy_fin_long" => "Das Kopieren ist abgeschlossen.",
		"prog_desc" => "Dieser Assistent hilft Ihnen beim <b>Kopieren von Festplatten oder Partitionen</b>. Das Programm ist in der Lage, auch im Falle defekter Blöcke einen Großteil der Daten zu kopieren.\n\nIm Gegensatz zu anderen Imaging- oder Kopierprogrammen kopiert dieses Werkzeug auch unbelegte Blöcke. So können Sie sogar von Kopien defekter Festplatten noch gelöschte Dateien wiederherstellen. Ein weiteres Einsatzbeispiel ist der Umzug eines kompletten Betriebssystems auf eine größere Festplatte. Nach dem Kopieren können Sie mit Partitionierungsprogrammen wie GParted die enthaltenen Partitionen auf den freien Platz strecken.\n\nDie neue Festplatte muss mindestens so groß sein wie die alte.",
		"select_drive" => "Wählen Sie das Laufwerk, welches Sie kopieren wollen. Sie können einzelne Partitionen oder gesamte Festplatten kopieren. Für einen Umzug ist die Auswahl der gesamten Festplatte notwendig, zur Vorbereitung einer Datenrettung genügt in der Regel das Kopieren einer einzelnen Partition.",
		"select_part" => "Inhalt einer Partition kopieren",
		"select_disk" => "Ganze Festplatte kopieren",
		"select_label" => "Exakte Kopie von Festplatten",
		"select_short" => "Auswahl des Quelllaufwerkes" ,
		"target_desc" => "Wählen Sie das Ziellaufwerk. Es werden nur Laufwerke angezeigt, welche mindestens die Größe des im letzten Schritt ausgewählten Quelllaufwerkes haben.",
		"target_short" => "Auswahl des Zieles",
		"confirm" => "Wollen Sie das Kopieren mit den vorgenommenen Einstellungen durchführen?",
		"disclaimer" => "<b>Haftungsausschluß:</b> Ich bin mir bewußt, dass beim Kopieren alle bislang vorhandenen Daten auf der Zielfestplatte oder -partition überschrieben werden und unwiederbringlich verloren sind.",
		"overview" => "Zusammenfassung",
		"hours" => "Stunden",
		"minutes" => "Minuten",
		"ovlabel" => "<b>Quelllaufwerk:</b> %SOURCE%\n\n<b>Ziellaufwerk:</b> %TARGET%\n\n<b>Geschätzte Dauer:</b>  %MINTIME% bis %MAXTIME% %UNIT%"
	},
	"en" => {
		"prog_title" => "Clone drives",
		"unknown_fs" => "Unknown file system",
		"no_part_found" => "No suitable source partition found - you might unmount some drives",
		"no_disk_found" => "No suitable source disk found - you might unmount some drives",
		"no_target_found" => "No suitable target drive found",
		"terminal_run" => "Cloning bitwise, run %N% - Please do not close",
		"copy_fin_short" => "Copying finished",
		"copy_fin_long" => "Copying is finished.",
		"prog_desc" => "This program helps you <b>cloning hard disks or partitions</b>. Even in the case of damaged sectors a large part of the data can be copied.\n\nContrary to other cloning or imaging tools blocks that are not occupied are also copied. This enables you to rescue data from the clone of a damaged hard disk. Another example of usage is moving a complete operating system to a larger hard disk. After cloning you might use GParted to stretch the partitions on the target drive.\n\nThe target drive has to be at least the size of the source drive.",
		"select_drive" => "Select the drive that you want to clone. You can copy whole disks or single partitions.When moving an operating system, we recommend selecting a whole disk, to prepare retrieval of deleted data usually partition suffices.",
		"select_part" => "Clone content of a partition",
		"select_disk" => "Clone whole disk",
		"select_label" => "Exact copy of disks",
		"select_short" => "Select source drive" ,
		"target_desc" => "Select the target drive. Drives are just shown here if they have at least the size of the source selected in the last step.",
		"target_short" => "Select target drive",
		"confirm" => "Do you want to start cloning with the selected settings?",
		"disclaimer" => "<b>Disclaimer:</b> I am aware of the fact that after cloning all data on the target drive is overwritten irreversible.",
		"overview" => "Overview",
		"hours" => "hours",
		"minutes" => "minutes",
		"ovlabel" => "<b>Source drive:</b> %SOURCE%\n\n<b>Target drive:</b> %TARGET%\n\n<b>Estimated duration:</b>  %MINTIME% to %MAXTIME% %UNIT%"
	},
	"pl" => {
		 "prog_title" => "Klonowanie dysków",
                "unknown_fs" => "Nieznany system plików",
                "no_part_found" => "Nie odnaleziono partycji źródłowych - być może musisz odmontować napęd(y)",
                "no_disk_found" => "Nie odnaleziono napędu źródłowego - być może musisz odmontować napęd(y)",
                "no_target_found" => "Nie odnaleziono napędu docelowego",
                "terminal_run" => "Klonowanie bit-w-bit, przebieg %N% - nie zamykaj tego okna",
                "copy_fin_short" => "Kopiowanie zakończone",
                "copy_fin_long" => "Kopiowanie zostało zakończone pomyślnie.",
                "prog_desc" => "Niniejszy program umożliwia <b>klonowanie całych dysków lub pojedynczych partycji</b>. Można skopiować dużą część danych nawet z uszkodzonych sektorów.\n\nW odróżnieniu od innych narzędzi do klonowania i kopiowania, bloki niezajęte danymi również zostaną skopiowane. Umożliwia to odzyskanie skasowanych danych z klonu uszkodzonego dysku twardego. Innym scenariuszem użycia programu jest przeniesienie całęgo systemu operacyjnego na większy dysk. Po sklonowaniu można wówczas użyć GParted do powiększenia partycji na dysku docelowym.\n\nNapęd docelowy musi być przynajmniej tak samo pojemny jak źródłowy.",
                "select_drive" => "Wybierz napęd, który chcesz sklonować. Możesz klonować cały dysk lub poszczególne partycje. Jeśli przenosisz system operacyjny, zalecane jest sklonowanie całego dysku; do odzyskiwania skasowanych danych zwykle wystarczy sklonowanie partycji.",
                "select_part" => "Klonuj zawartość partycji",
                "select_disk" => "Klonuj cały dysk",
                "select_label" => "Dokładna kopia dysku",
                "select_short" => "Wybierz napęd źródłowy" ,
                "target_desc" => "Wybierz napęd docelowy. Lista zawiera jedynie napędy o pojemności nie mniejszej niż napęd źródłowy wybrany w poprzednim kroku.",
                "target_short" => "Wybierz napęd docelowy",
                "confirm" => "Czy chcesz rozpocząć klonowanie z wybranymi ustawieniami?",
                "disclaimer" => "<b>Oświadczenie:</b> Jestem świadom, iż po sklonowaniu nie będzie możliwe odzyskanie danych składowanych wcześniej na dysku docelowym.",
                "overview" => "Podsumowanie",
                "hours" => "godzin",
                "minutes" => "minut",
                "ovlabel" => "<b>Napęd źródłowy:</b> %SOURCE%\n\n<b>Napęd docelowy:</b> %TARGET%\n\n<b>Przybliżony czas operacji:</b>  %MINTIME% do %MAXTIME% %UNIT%"
	},
	"es" =>  {
		"prog_title" => "Clonar unidades",
                "unknown_fs" => "Archivo de sistema desconocido",
                "no_part_found" => "No se ha encontrado una partición de origen adecuada. Es posible que necesite desmontar alguna unidad",
                "no_disk_found" => "No se ha encontrado ningún disco de origen adecuado. Es posible que necesite desmontar alguna unidad",
                "no_target_found" => "No se ha encontrado una unidad de destino adecuada",
                "terminal_run" => "Ejecutar copia bit a bit %N% - Por favor, no cerrar",
                "copy_fin_short" => "Copia terminada",
                "copy_fin_long" => "La copia se ha completado.",
                "prog_desc" => "Este programa permite <b>copias completas de discos o particiones separadas</b>. Incluso en el caso de que hubiera sectores dañados, gran parte de los datos se podrán copiar.\n\nContrary to other cloning or imaging tools blocks that are not occupied are also copied. Esto le permite recuperar datos desde la copia de un disco duro dañado. Otro ejemplo de uso es mover un sistema operativo completo a un disco duro de mayor capacidad. Después de la copia debe usar GParted para ampiar el tamaño de las particiones en la unidad de destino.\n\nLa unidad de destino debe tener, al menos, el mismo tamaño que la unidad de origen.",
                "select_drive" => "Seleccione la unidad que desea clonar. Puede copiar el disco completo o particiones simples. Para copiar un sistema operativo, recomendamos el disco completo. Para preparar la recuperación de datos, por lo general basta la partición.",
                "select_part" => "Clonar el contenido de una partición",
                "select_disk" => "Clonar el disco completo",
                "select_label" => "Copias exactas de los discos",
                "select_short" => "Seleccionar la unidad de origen" ,
                "target_desc" => "Seleccionar la unidad de destino. Las unidades se muestran sólo si tienen el tamaño de la fuente seleccionada en el último paso.",
                "target_short" => "Seleccionar la unidad de destino",
                "confirm" => "¿Desea comenzar el proceso de copia con la configuración seleccionada?",
                "disclaimer" => "<b>Exención de responsabilidad:</b> Soy consciente de que después de clonar todos los datos, la unidad de destino se sobreescribirá de forma irreversible.",
                "overview" => "Información general",
                "hours" => "horas",
                "minutes" => "minutos",
                "ovlabel" => "<b>Unidad de origen:</b> %SOURCE%\n\n<b>Unidad de destino:</b> %TARGET%\n\n<b>Duración estimada:</b>  %MINTIME% to %MAXTIME% %UNIT%"
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
targets = []
nicetargets = []
xml_read_count = 0
initdone = false

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
								ifstype = "unbekanntes Dateisystem"
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
	if new_rows < 1
		partcombo.append_text(extract_lang_string("no_part_found"))
		partcombo.active = 0
		partcombo.sensitive = false
	end
	if disk_rows < 1
		drivecombo.append_text(extract_lang_string("no_disk_found"))
		drivecombo.active = 0
		drivecombo.sensitive = false
	end
	partcombo.active = 0
	drivecombo.active = 0
	return new_rows, part_array, disk_rows, disk_array, niceparts, nicedrives, partsizes, drivesizes
end


def update_target_combo(disks, targetcombo, partcombo, partarray, niceparts, drivecombo, diskarray, nicedrives, use_part)
	100.downto(0) { |i|
		begin
			targetcombo.remove_text(i)
		rescue
		end
	}
	begin
		$stderr.puts "Use partition: " + use_part.to_s
		$stderr.puts "Selected partition: " + partarray[partcombo.active].to_s + " " + niceparts[partcombo.active].to_s
		$stderr.puts "Selected disk: " + diskarray[drivecombo.active].to_s + " " + nicedrives[drivecombo.active].to_s
	rescue
	end
	targets = Array.new
	nicetargets = Array.new
	minsize = 0
	disks.each { |d|
		if use_part == true && !d[5].nil?
			d[5].each { |p|	minsize = p[5] if partarray[partcombo.active] == p[0] }
		else	
			minsize = d[2] if diskarray[drivecombo.active] == d[6] 
		end
	}
	puts "Minimum size: " + minsize.to_s
	disks.each { |d|
		sizestr = ""
		if d[2] > 7_900_000_000
			sizestr = ((d[2].to_f / 1073741824 ) + 0.5).to_i.to_s + "GB"
		else
			sizestr = (d[2].to_f / 1048576 ).to_i.to_s + "MB"
		end
		businfo = "IDE/SATA"
		businfo = "USB" if d[0] =~ /^usb/
		if use_part == true && !d[5].nil?
			d[5].each { |p|
				psize = ""
				if p[5] > 7_900_000_000
					psize = ((p[5].to_f / 1073741824 ) + 0.5).to_i.to_s + "GB"
				else
					psize = (p[5].to_f / 1048576 ).to_i.to_s + "MB"
				end
				unless p[2] == "mounted" || p[0] =~ /^\/dev\/sr/ || 
					p[5] < minsize || partarray[partcombo.active] == p[0] 
					puts p[0].to_s + " " + p[5].to_s + " " + p[2].to_s
					targets.push(p[0])
					nicetarget = d[1] + " (" + businfo + ", " + sizestr + ") Partition " +
						p[0] + " (" + p[1] + ", " + psize + ")"
					nicetargets.push(nicetarget)
					targetcombo.append_text(nicetarget)
					targetcombo.sensitive = true
				end
			}
		elsif !(d[6].strip =~ /^\/dev\/sr/)
			# find out if mounted
			is_mounted = false
			d[5].each { |p| is_mounted = true if p[2] == "mounted" } unless d[5].nil?
			if d[2] >= minsize && is_mounted == false && diskarray[drivecombo.active] != d[6] 
				puts d[1] + " " + d[2].to_s
				targets.push(d[6])
				nicetarget = d[1] + " " + d[6] + " (" + businfo + ", " + sizestr + ")"
				nicetargets.push(nicetarget)
				targetcombo.append_text(nicetarget)
				targetcombo.sensitive = true
			end
		end
		
	}
	if targets.size < 1
		targetcombo.append_text(extract_lang_string("no_target_found"))
		targetcombo.sensitive = false
	end
	targetcombo.active = 0
	return targets, nicetargets
end

#========================================
# Core logic
#========================================

def apply_settings(source_dev, target_dev, assi)
	logfile = "/tmp/ddrescue_" + rand(10_000_000_000).to_s
	command = "ddrescue --force --no-split " + source_dev + " " + target_dev + " " + logfile 
	puts command
	if $dummy == false
		system("Terminal --geometry=80x12 --hide-toolbars --hide-menubar --disable-server -T \"" + 
		extract_lang_string("terminal_run").gsub("%N%", "1") + "\" -x " + command)
	end
	command = "ddrescue --force --direct --max-retries=3 " + source_dev + " " + target_dev + " " + logfile 
	puts command
	if $dummy == false
		system("Terminal --geometry=80x12 --hide-toolbars --hide-menubar --disable-server -T \"" + 
		extract_lang_string("terminal_run").gsub("%N%", "2") + "\" -x " + command)
	end
	command = "ddrescue --force --direct --retrim --max-retries=3 " + source_dev + " " + target_dev + " " + logfile
	puts command
	if $dummy == false
		system("Terminal --geometry=80x12 --hide-toolbars --hide-menubar --disable-server -T \"" + 
		extract_lang_string("terminal_run").gsub("%N%", "3") + "\" -x " + command)
	end
	dialog = Gtk::Dialog.new(extract_lang_string("copy_fin_short"),assi,Gtk::Dialog::MODAL,
			[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
		)
	dialog.has_separator = false
	label = Gtk::Label.new(extract_lang_string("copy_fin_long"))
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
	system("sudo /sbin/mdev -s")
end

#========================================
# First window - tell the user what we do
#========================================

desclabel = Gtk::Label.new
desclabel.set_markup(extract_lang_string("prog_desc"))
desclabel.wrap = true
desclabel.width_request = 550
desclabel.xalign = 0.1

descpage = assi.append_page(desclabel)
assi.set_page_title(desclabel, extract_lang_string("select_label") )
assi.set_page_type(desclabel, Gtk::Assistant::PAGE_CONTENT)
assi.set_page_complete(desclabel, true) # false)

#========================================
# Second window - choose the source dev
#========================================

partlabel = Gtk::Label.new(extract_lang_string("select_drive"))
partlabel.wrap = true
partlabel.width_request = 550
partlabel.xalign = 0.1

partbox = Gtk::VBox.new(false, 5)
partbox.pack_start(partlabel, false, true, 5)

partradio = Gtk::RadioButton.new(extract_lang_string("select_part"))
partcombo = Gtk::ComboBox.new
# partcombo.append_text("/dev/sda1 Hulla")
# partcombo.append_text("/dev/sdb9 Bulla")
# partcombo.active = 0
partrows = 0
partbox.pack_start(partradio, false, true, 5)
partbox.pack_start(partcombo, false, true, 5)
diskradio = Gtk::RadioButton.new(partradio, extract_lang_string("select_disk"))
diskcombo = Gtk::ComboBox.new
# diskcombo.append_text("/dev/sda Hulla")
# diskcombo.append_text("/dev/sdb Bulla")
# diskcombo.active = 0
diskrows = 0
diskcombo.sensitive = false
partbox.pack_start(diskradio, false, true, 5)
partbox.pack_start(diskcombo, false, true, 5)

partpage = assi.append_page(partbox)
assi.set_page_title(partbox, extract_lang_string("select_short") )
assi.set_page_type(partbox, Gtk::Assistant::PAGE_CONTENT)
assi.set_page_complete(partbox, false)

#========================================
# Third window - choose the target dev
#========================================

targlabel = Gtk::Label.new
targlabel.set_markup(extract_lang_string("target_desc"))
targlabel.wrap = true
targlabel.width_request = 550
targlabel.xalign = 0.1

targcombo = Gtk::ComboBox.new

targbox = Gtk::VBox.new(false, 5)
targbox.pack_start(targlabel, false, true, 5)
targbox.pack_start(targcombo, false, true, 5)

targpage = assi.append_page(targbox)
assi.set_page_title(targbox, extract_lang_string("target_short") )
assi.set_page_type(targbox, Gtk::Assistant::PAGE_CONTENT)
assi.set_page_complete(targbox, false)

#========================================
# Last window - confirm the settings
#========================================

lastlabel = Gtk::Label.new(extract_lang_string("confirm"))
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

partcombo.signal_connect('changed') {
	lastcheck.active = false
	assi.set_page_complete(lastbox, false)
	targets, nicetargets = update_target_combo(alldisks, targcombo, partcombo, 
		partarray, niceparts, diskcombo, diskarray, nicedrives, partradio.active?) if initdone == true
	if targets.size > 0 
		assi.set_page_complete(targbox, true)
	else
		assi.set_page_complete(targbox, false)
	end
}

diskcombo.signal_connect('changed') {
	lastcheck.active = false
	assi.set_page_complete(lastbox, false)
	targets, nicetargets = update_target_combo(alldisks, targcombo, partcombo, 
		partarray, niceparts, diskcombo, diskarray, nicedrives, partradio.active?) if initdone == true
	if targets.size > 0 
		assi.set_page_complete(targbox, true)
	else
		assi.set_page_complete(targbox, false)
	end
}

partradio.signal_connect("clicked") { |b|
	lastcheck.active = false
	assi.set_page_complete(lastbox, false)
	diskcombo.sensitive = false
	partcombo.sensitive = true
	targets, nicetargets = update_target_combo(alldisks, targcombo, partcombo, partarray, 
		niceparts, diskcombo, diskarray, nicedrives, partradio.active?) if initdone == true
	if targets.size > 0 
		assi.set_page_complete(targbox, true)
	else
		assi.set_page_complete(targbox, false)
	end
}

diskradio.signal_connect("clicked") { |b|
	lastcheck.active = false
	assi.set_page_complete(lastbox, false)
	partcombo.sensitive = false
	diskcombo.sensitive = true
	targets, nicetargets = update_target_combo(alldisks, targcombo, partcombo, partarray, 
		niceparts, diskcombo, diskarray, nicedrives, partradio.active?) if initdone == true
	if targets.size > 0 
		assi.set_page_complete(targbox, true)
	else
		assi.set_page_complete(targbox, false)
	end
}

targcombo.signal_connect('changed') {  |b|
	assi.set_page_complete(lastbox, false)
	lastcheck.active = false
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
	source_dev = diskarray[diskcombo.active]
	source_dev = partarray[partcombo.active] if partradio.active? == true
	apply_settings(source_dev, targets[targcombo.active], w)
	w.destroy
}

assi.set_forward_page_func{|curr|
	#searchformats = []
	#formatcount = 0
	#format_checkboxes.each { |c|
	#	searchformats.push(formats[formatcount]) if c.active?
	#	formatcount += 1
	#}
	scandev = ""
	nicedev = ""
	scansize = 0
	mintime = 0
	maxtime = 0
	if partradio.active? == true
		scandev = partarray[partcombo.active]
		nicedev = niceparts[partcombo.active]
		scansize = partsizes[partcombo.active]
	else
		scandev = diskarray[diskcombo.active]
		nicedev = nicedrives[diskcombo.active]
		scansize = drivesizes[diskcombo.active]
	end
	maxtime = scansize.to_i / 720_000_000
	mintime = scansize.to_i / 3_600_000_000
	minmaxunit = extract_lang_string("minutes")
	if mintime > 120
		mintime = scansize.to_i / 3_600_000_000 / 60
		maxtime = scansize.to_i / 720_000_000 / 60
		minmaxunit = extract_lang_string("hours")
	end
	begin	
		# "<b>Quelllaufwerk:</b> %SOURCE%\n\n<b>Ziellaufwerk:</b> %TARGET%\n\n<b>Geschätzte Dauer:</b>  %MINTIME% bis %MAXTIME% %UNIT%"
		ovlabel.set_markup(extract_lang_string("ovlabel").gsub("%SOURCE%", nicedev.to_s).gsub("%TARGET%", nicetargets[targcombo.active]).
			gsub("%MINTIME%", mintime.to_s).gsub("%MAXTIME%", maxtime.to_s).gsub("%UNIT%", minmaxunit))
	rescue
	end
	#	" überschreiben\n\n<b>Benötigte Zeit:</b> " + 
	#	mintime.to_i.to_s + " bis " + maxtime.to_i.to_s + minmaxunit + " (geschätzt)" )
	puts curr
	if curr == 0
		# when switching from first to second screen, read drivelist
		puts "current screen 0, rereading drivelist"
		alldisks = scan_parts(read_devs) if xml_read_count < 1
		
		#alldisks.each { |d|
			# d[0] businfo
			# d[1] Name
			# d[2] Größe in Bytes
			# d[3] Einheit
			# d[4] Boolean CDROM
			# d[5] Partitionen / Array
			# d[5][0][0] Device 
			# d[5][0][1] Filesystem
			# d[5][0][2] Mounted (String)
			# d[5][0][4] Mounted (Boolean)
			#puts " -+- " + d[5][0][6].to_s + " -+-"
		#}
		if xml_read_count < 1
			partrows, partarray, diskrows, diskarray, niceparts, nicedrives, partsizes, drivesizes = 
				update_partcombo(alldisks, partcombo, partrows, diskcombo, diskrows)
		end
		targets, nicetargets = update_target_combo(alldisks, targcombo, partcombo, partarray, niceparts, diskcombo, diskarray, nicedrives, partradio.active?) if xml_read_count < 1
		xml_read_count += 1
		if diskrows < 1 
			diskradio.sensitive = false
			diskcombo.sensitive = false
		else
			diskradio.sensitive = true
		end
		if partrows < 1 
			partradio.sensitive = false
			partcombo.sensitive = false
			diskradio.active = true
		else
			partradio.sensitive = true
		end
		if diskrows + partrows > 0
			assi.set_page_complete(partbox, true)
		else
			assi.set_page_complete(partbox, false)
		end
		if targets.size > 0 
			assi.set_page_complete(targbox, true)
		else
			assi.set_page_complete(targbox, false)
		end
		initdone = true
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