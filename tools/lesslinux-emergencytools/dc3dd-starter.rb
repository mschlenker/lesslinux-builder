#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
require "rexml/document"

# License? GPL v2.0

LANGUAGE = ENV['LANGUAGE'][0..1]

#@xbranding = File.new( "/etc/lesslinux/branding/branding.xml" )
#@branding = REXML::Document.new  @xbranding

LOCSTRINGS = {
	"de" => {
		"prog_title" => "Datenlöschung",
		"unknown_fs" => "Unbekanntes Dateisystem",
		"no_part_found" => "Keine Partition zum Löschen gefunden - ggf. Laufwerkseinbindungen lösen",
		"no_disk_found" => "Keine Festplatte zum Löschen gefunden - ggf. Laufwerkseinbindungen lösen",
		"deleting" => "Löschung, Durchlauf ",
		"do_not_close" => "Bitte nicht schließen",
		"del_completed_short" => "Löschen abgeschlossen",
		"del_completed_long" => "Das Löschen des Laufwerkes %DEVICE% ist abgeschlossen! Es wird nun die Protokolldatei angezeigt.",
		"prog_desc" => "Dieser Assistent hilft Ihnen beim Löschen von Partitionen oder Festplatten mit dem Programm <b>dc3dd des US-Verteidigungsministeriums</b>. Dieses Werkzeug überschreibt komplette Festplatten oder einzelne Partitionen mit Zufallswerten, so dass gespeicherten Daten nicht mehr wiederherzustellen sind. Eine so gelöschte Festplatte können Sie bedenkenlos weitergeben.",
		"what_to_delete" => "Wählen Sie das Laufwerk, welches Sie löschen wollen. Sie können einzelne Partitionen oder gesamte Festplatten löschen. Für eine Komplettlöschung empfehlen wir die Auswahl der gesamten Festplatte. Achtung: Es werden nur Laufwerke angezeigt, die momentan nicht im Zugriff sind!",
		"start_title" => "Datenlöschung starten",
		"method_desc" => "Wählen Sie die Löschmethode: Nach heutigem Stand der Technik lassen sich Daten nicht mehr wiederherstellen, die einmal mit Nullen überschrieben wurden. Um auf Nummer sicher zu gehen, wählen Sie das zweimalige Überschreiben mit Zufallswerten.",
		"delete_part" => "Inhalt einer Partition löschen",
		"delete_disk" => "Inhalt einer Festplatte löschen",
		"method_zero" => "Mit Nullen überschreiben",
		"method_random" => "Mit Zufallswerten überschreiben",
		"method_choice" => "Auswahl der Löschmethode",
		"method count" => "mal löschen",
		"drive_choice" => "Auswahl des Laufwerkes",
		"do_you_want" => "Wollen Sie die Löschung mit den vorgenommenen Einstellungen durchführen?",
		"disclaimer" => "<b>Haftungsausschluß:</b> Ich bin mir bewußt, dass die Löschung unwiederbringlich erfolgt und eine falsche Laufwerksauswahl fatale Folgen haben kann. Ebenso ist mir bekannt, dass eine Löschung beschädigter Datenträger nicht immer vollständig möglich ist.",
		"overview" => "Zusammenfassung",
		"hours" => "Stunden",
		"minutes" => "Minuten",
		"zero_short" => "Nullen",
		"random_short" => "Zufallszahlen",
		"disk_short" => "Festplatte",
		"part_short" => "Partition",
		"overview_long" => "<b> %DRIVESTR% löschen:</b> %NICEDEV%\n\n<b>Methode:</b> %COUNT% mal mit %METHOD% überschreiben\n\n<b>Benötigte Zeit:</b> %MINTIME% bis %MAXTIME% %UNIT% (geschätzt)"
	},
	"en" => {
		"prog_title" => "Data deletion",
		"unknown_fs" => "Unknown file system",
		"no_part_found" => "No partition found that can be deleted - you might unmount some drives",
		"no_disk_found" => "No disk found that can be deleted - you might unmount some drives",
		"deleting" => "Deleting, run ",
		"do_not_close" => "Please do not close",
		"del_completed_short" => "Deleting completed",
		"del_completed_long" => "Deleting device %DEVICE% is completed! The log file will be shown now.",
		"prog_desc" => "This assistent helps deleting the content of hard disks or partitions with the program <b>dc3dd from the US Department of Defense</b>. It overwrites complete drives or partitions with random data, so that formerly stored data is not accessible anymore. A hard disk that was deleted this way might be given away without any fear of los privacy.",
		"what_to_delete" => "Choose the drive you want to delete. You can delete the content of partitions or whole hard disks. For a complete deletion we recommend choosing a whole drive. Warning: Only drives are shown that are currently not mounted!",
		"start_title" => "Start deletion",
		"method_desc" => "Choose the deletion method: According to current state of technology data cannot be revealed anymore after overwriting once with zeroes. To be sure you might want to overwrite twice with random data.",
		"delete_part" => "Delete content of a partition",
		"delete_disk" => "Delete content of a hard disk",
		"method_zero" => "Overwrite with zeroes",
		"method_random" => "Overwrite with random data",
		"method_choice" => "Choose the deletion method",
		"method_count" => "times", 
		"drive_choice" => "Choose the target drive",
		"do_you_want" => "Do you want to start deleting with the selected settings?",
		"disclaimer" => "<b>Disclaimer:</b> I am aware that the deletion is irreversible and the wrong choice of the target can have fatal consequences. I am also aware that the deletion might not be completely possible in all cases.",
		"overview" => "Zusammenfassung",
		"hours" => "hours",
		"minutes" => "minutes",
		"zero_short" => "zeroes",
		"random_short" => "random data",
		"disk_short" => "hard disk",
		"part_short" => "partition",
		"overview_long" => "<b>Delete %DRIVESTR%:</b> %NICEDEV%\n\n<b>Method:</b> Overwrite %COUNT% times with %METHOD%\n\n<b>Estimated time:</b> %MINTIME% to %MAXTIME% %UNIT%"
	},
	"pl" => {
		 "prog_title" => "Wymazywanie danych",
                "unknown_fs" => "Nieznany system plików",
                "no_part_found" => "Nie odnaleziono żadnych partycji, które mozna wymazać - być może musisz odmontować napęd(y)",
                "no_disk_found" => "Nie odnaleziono żadnego napędu, który można wymazać - być może musisz odmontować napęd(y)",
                "deleting" => "Wymazywanie, przebieg ",
                "do_not_close" => "Nie zamykaj tego okna",
                "del_completed_short" => "Wymazywanie zakończone",
                "del_completed_long" => "Wymazywanie urządzenia %DEVICE% zostało zakończone! Zobaczysz teraz plik dziennika.",
                "prog_desc" => "Niniejszy kreator umżliwia usunięcie zawartości partycji czy dysku twardego przy pomocy programu <b>dc3dd z Departamentu Obrony USA</b>. Zapisuje on całą powierzchnię dysku lub partycji losowymi danymi, aby uniemożliwić odczytanie uprzednio składowanych tam informacji. Po usunięciu danych w ten sposób możesz sprzedać lub oddać dysk i nie bać się, że ktoś odczyta Twoje dane.",
                "what_to_delete" => "Wybierz napęd, którego zawartość chcesz wymazać. Możesz wskazać cały napęd lub pojedynczą partycję. W celu uzyskania całkowitej pewności zalecamy wymazanie całego dysku. Uwaga: lista zawiera jedynie niezamontowane napędy!",
                "start_title" => "Rozpocznij wymazywanie",
                "method_desc" => "Wybierz metodę wymazywania: obecne technologie nie pozwalają odczytać danych nadpisanych jednokrotnie zerami. Dla całkowitej pewności możesz wybrać dwukrotne neadpisanie losowymi danymi.",
                "delete_part" => "Wymaż zawartość partycji",
                "delete_disk" => "Wymaż zawartość dysku",
                "method_zero" => "Nadpisz zerami",
                "method_random" => "Nadpisz losowymi danymi",
                "method_choice" => "Wybierz metodę wymazywania",
                "method_count" => "razy",
                "drive_choice" => "Wybierz napęd docelowy",
                "do_you_want" => "Czy chcesz rozpocząć wymazywanie z wybranymi ustawieniami?",
                "disclaimer" => "<b>Oświadczenie:</b> Jestem świadom, że wymazywanie jest nieodwracalne, i że wybór niewłaściwego napędu/partycji może mieć poważne konsekwencje. Jestem również świadom, że nie we wszystkich przypadkach możliwe jest kompletne wymazanie informacji.",
                "overview" => "Podsumowanie",
                "hours" => "godzin",
                "minutes" => "minut",
                "zero_short" => "zerami",
                "random_short" => "losowymi danymi",
                "disk_short" => "dysk twardy",
                "part_short" => "partycja",
                "overview_long" => "<b>Wymazywanie %DRIVESTR%:</b> %NICEDEV%\n\n<b>Metoda:</b> Nadpisywanie %COUNT% razy %METHOD%\n\n<b>Przybliżony czas:</b> %MINTIME% do %MAXTIME% %UNIT%"
	},
	"es" => {
		"prog_title" => "Eliminación de datos",
                "unknown_fs" => "Sistema de archivo desconocido",
                "no_part_found" => "No se encontró ninguna partición para ser eliminada. Puede que necesite montar alguna unidad",
                "no_disk_found" => "No se encontró ningún disco para ser eliminado. Puede que necesite montar alguna unidad",
                "deleting" => "Borrar ahora",
                "do_not_close" => "Por favor, no cerrar",
                "del_completed_short" => "Borrado completo",
                "del_completed_long" => "Eliminación del dispositivo %DEVICE% completa. El archivo de registro se mostrará ahora.",
                "prog_desc" => "Este asistente le ayudará a borrar el contenido de las unidades o las particiones con el programa <b>dc3dd del Departamento de Defensa de EEUU</b>. Esta aplicación sobreescribe completamente las unidades de disco o particiones con datos aleatorios, por lo que no podrá acceder nunca más a los datos anteriormente guardados. Una unidad borrada de este modo podría ser entregada a cualquiera sin temer por la privacidad.",
                "what_to_delete" => "Elija la unidad que desea borrar. Puede eliminar el contenido de las particiones o la unidad de disco completa. Para un borrado total recomendamos elegir la unidad completa. Precaución: Únicamente se mostrarán las unidades que no están montadas.",
                "start_title" => "Iniciar borrado",
                "method_desc" => "Elegir el método de borrado: Una vez sobreescritos con ceros los datos con esta tecnología, no podrán ser recuperados nunca más. Para estar más seguro, se pueden sobreescribir dos veces con datos aleatorios.",
                "delete_part" => "Borrar el contenido de una partición",
                "delete_disk" => "Borrar el contenido de un disco duro",
                "method_zero" => "Sobreescribir con ceros",
                "method_random" => "Sobreescribir con datos aleatorios",
                "method_choice" => "Elegir el método de borrado",
                "method_count" => "Número de veces",
                "drive_choice" => "Elegir la unidad de destino",
                "do_you_want" => "¿Desea comenzar el proceso de borrado con la configuración seleccionada?",
                "disclaimer" => "<b>Exención de responsabilidad:</b> Soy consciente de que el borrado será definitivo y un error en la elección de la unidad de destino puede traer consecuencias fatales. También soy consciente de que el borrado podría no ser completamente posible en todos los casos.",
                "overview" => "Información general",
                "hours" => "horas",
                "minutes" => "minutos",
                "zero_short" => "ceros",
                "random_short" => "datos aleatorios",
                "disk_short" => "disco duro",
                "part_short" => "partición",
                "overview_long" => "<b>Eliminar %DRIVESTR%:</b> %NICEDEV%\n\n<b>Método:</b> Sobreescribir con %COUNT% veces %METHOD%\n\n<b>Tiempo estimado:</b> %MINTIME% a %MAXTIME% %UNIT%"
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
								ifstype = extract_lang_string("unknown_fs")
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

def apply_settings(assi, device, pattern, count)
	puts "Device: " + device.to_s
	puts "How often? " + count.to_s
	puts "Use complex pattern? " + pattern.to_s
	puts "Alles hat ein Ende!"
	logfile = ""
	IO.popen("dd if=/dev/urandom bs=1M count=3 | sha1sum") { |i|
		while i.gets
			cols = $_.split
			logfile = cols[0].strip
		end
	}
	0.upto(count.to_i - 1) { |i|
		hexpat = "deadbeef"
		IO.popen("dd if=/dev/urandom bs=1M count=3 | sha1sum") { |j|
			while j.gets
				cols = $_.split
				hexpat = cols[0].strip
			end
		}
		command = "dc3dd wipe=" + device + " log=/tmp/dc3dd_errors_" + logfile + ".txt" 
		command = command + " tpat=" + hexpat if pattern == true
		puts command
		if $dummy == false
			system("Terminal --geometry=80x12 --hide-toolbars --hide-menubar --disable-server -T \"" + extract_lang_string("deleting") + " " + (i + 1).to_s + 
				" - " + extract_lang_string("do_not_close") + "\" -x " + command)
		end
	}
	
	dialog = Gtk::Dialog.new(extract_lang_string("del_completed_short"),assi,Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.has_separator = false
	label = Gtk::Label.new(extract_lang_string("del_completed_long").gsub("%DEVICE%", device))
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
	# assi.destroy
	system("sudo /sbin/mdev -s")
	system("chown surfer /tmp/dc3dd_errors_" + logfile + ".txt")
	system("su surfer -c 'exo-open /tmp/dc3dd_errors_" + logfile + ".txt'")
	assi.destroy
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
assi.set_page_title(desclabel, extract_lang_string("start_title"))
assi.set_page_type(desclabel, Gtk::Assistant::PAGE_CONTENT)
assi.set_page_complete(desclabel, true) # false)

#========================================
# Second window - choose the partition
#========================================

partlabel = Gtk::Label.new(extract_lang_string("what_to_delete"))
partlabel.wrap = true
partlabel.width_request = 550
partlabel.xalign = 0.1

partbox = Gtk::VBox.new(false, 5)
partbox.pack_start(partlabel, false, true, 5)

partradio = Gtk::RadioButton.new(extract_lang_string("delete_part"))
partcombo = Gtk::ComboBox.new
# partcombo.append_text("/dev/sda1 Hulla")
# partcombo.append_text("/dev/sdb9 Bulla")
# partcombo.active = 0
partrows = 0
partbox.pack_start(partradio, false, true, 5)
partbox.pack_start(partcombo, false, true, 5)
diskradio = Gtk::RadioButton.new(partradio, extract_lang_string("delete_disk"))
diskcombo = Gtk::ComboBox.new
# diskcombo.append_text("/dev/sda Hulla")
# diskcombo.append_text("/dev/sdb Bulla")
# diskcombo.active = 0
diskrows = 0
diskcombo.sensitive = false
partbox.pack_start(diskradio, false, true, 5)
partbox.pack_start(diskcombo, false, true, 5)

partpage = assi.append_page(partbox)
assi.set_page_title(partbox, extract_lang_string("drive_choice") )
assi.set_page_type(partbox, Gtk::Assistant::PAGE_CONTENT)
assi.set_page_complete(partbox, false)

#========================================
# Third window - choose method
#========================================

typelabel = Gtk::Label.new

typelabel.wrap = true
typelabel.width_request = 550
typelabel.xalign = 0.1
typelabel.set_markup(extract_lang_string("method_desc"))

typeradio = Gtk::RadioButton.new(extract_lang_string("method_zero"))
typeselec = Gtk::RadioButton.new(typeradio, extract_lang_string("method_random"))
typeselec.active = true
ddct = Gtk::SpinButton.new(1, 10, 1.0)
ddct.value = 2

typebox = Gtk::VBox.new(false, 5)
typebox.pack_start(typelabel, false, true, 5)
typebox.pack_start(typeradio, false, true, 5)
typebox.pack_start(typeselec, false, true, 5)
spinbox = Gtk::HBox.new(false, 5)
spinlabel = Gtk::Label.new(extract_lang_string("method_count"))
spinbox.pack_start(ddct, false, true, 5)
spinbox.pack_start(spinlabel, false, true, 5)

typebox.pack_start(spinbox, false, true, 5)

typepage = assi.append_page(typebox)
assi.set_page_title(typebox, extract_lang_string("method_choice") )
assi.set_page_type(typebox, Gtk::Assistant::PAGE_CONTENT)
assi.set_page_complete(typebox, true) # false)

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

lastcheck.signal_connect('clicked') { |b|
	if b.active? 
		assi.set_page_complete(lastbox, true)
	else
		assi.set_page_complete(lastbox, false)
	end
}

partcombo.signal_connect('changed') {
	lastcheck.active = false
	assi.set_page_complete(lastbox, false)
}

diskcombo.signal_connect('changed') {
	lastcheck.active = false
	assi.set_page_complete(lastbox, false)
}

partradio.signal_connect("clicked") { |b|
	lastcheck.active = false
	assi.set_page_complete(lastbox, false)
	diskcombo.sensitive = false
	partcombo.sensitive = true if partarray.size > 0
}

diskradio.signal_connect("clicked") { |b|
	lastcheck.active = false
	assi.set_page_complete(lastbox, false)
	partcombo.sensitive = false
	diskcombo.sensitive = true if diskarray.size > 0
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
	puts partarray[partcombo.active]
	puts diskarray[diskcombo.active]
	puts partradio.active?
	if partradio.active? == true
		scandev = partarray[partcombo.active]
		nicedev = niceparts[partcombo.active]
		scansize = partsizes[partcombo.active]
	else
		scandev = diskarray[diskcombo.active]
		nicedev = nicedrives[diskcombo.active]
		scansize = drivesizes[diskcombo.active]
	end
	apply_settings(w, scandev, typeselec.active?, ddct.value)
}

assi.set_forward_page_func{|curr|
	#searchformats = []
	#formatcount = 0
	#format_checkboxes.each { |c|
	#	searchformats.push(formats[formatcount]) if c.active?
	#	formatcount += 1
	#}
	scandev = nil
	nicedev = nil
	scantypes = []
	scansize = 0
	if partradio.active? == true
		scandev = partarray[partcombo.active]
		nicedev = niceparts[partcombo.active]
		scansize = partsizes[partcombo.active]
	else
		scandev = diskarray[diskcombo.active]
		nicedev = nicedrives[diskcombo.active]
		scansize = drivesizes[diskcombo.active]
	end
	if typeradio.active? == true
		scantypes = []
		searchfor = "allen Dateitypen"
	else
		#scantypes = searchformats
		scantype = []
		searchfor = "ausgewählten Dateitypen"
	end
	maxtime = ddct.value.to_i * scansize.to_i / 720_000_000
	mintime = ddct.value.to_i * scansize.to_i / 3_600_000_000
	minmaxunit = extract_lang_string("minutes")
	if mintime > 120
		mintime = ddct.value.to_i * scansize.to_i / 3_600_000_000 / 60
		maxtime = ddct.value.to_i * scansize.to_i / 720_000_000 / 60
		minmaxunit = extract_lang_string("hours")
	end
	ddmethod = extract_lang_string("zero_short")
	ddmethod = extract_lang_string("random_short") if typeselec.active?
	drivestr = extract_lang_string("part_short")
	drivestr = extract_lang_string("disk_short") if diskradio.active?
	# "<b> %DRIVESTR% löschen:</b> %NICEDEV%\n\n<b>Methode:</b> %COUNT% mal mit %METHOD% überschreiben\n\n<b>Benötigte Zeit:</b> %MINTIME% bis %MAXTIME% %UNIT% (geschätzt)",
	ovlabel.set_markup(extract_lang_string("overview_long").gsub("%DRIVESTR%", drivestr).
		gsub("%NICEDEV%", nicedev.to_s).gsub("%COUNT%", ddct.value.to_i.to_s).
		gsub("%METHOD%", ddmethod).gsub("%MINTIME%", mintime.to_i.to_s).
		gsub("%MAXTIME%", maxtime.to_i.to_s).gsub("%UNIT%", minmaxunit)
	)
	puts curr
	if curr == 0
		# when switching from first to second screen, read drivelist
		puts "current screen 0, rereading drivelist"
		alldisks = scan_parts(read_devs) if xml_read_count < 1
		xml_read_count += 1
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
		partrows, partarray, diskrows, diskarray, niceparts, nicedrives, partsizes, drivesizes = 
			update_partcombo(alldisks, partcombo, partrows, diskcombo, diskrows)
		if diskrows < 1 
			diskradio.sensitive = false
		else
			diskradio.sensitive = true
		end
		if partrows < 1 
			partradio.sensitive = false
			diskradio.active = true
		else
			partradio.sensitive = true
		end
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
