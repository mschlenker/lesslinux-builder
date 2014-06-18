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
		"prog_title" => "Datenwiederherstellung",
		"unknown_fs" => "Unbekanntes Dateisystem",
		"no_part_found" => "Keine geeignete Partition für die Suche gefunden - ggf. Laufwerkseinbindungen lösen",
		"no_disk_found" => "Keine geeignete Festplatte für die Suche gefunden - ggf. Laufwerkseinbindungen lösen",
		"do_not_close" => "Bitte nicht schließen!",
		"rec_fin_short" => "Datenrettung abgeschlossen",
		"rec_fin_long" => "Die Datenrettung ist abgeschlossen!",
		"rec_fin_fail" => "Der Zielordner ist voll. Möglicherweise konnten nicht alle Dateien gesichert werden!",
		"assi_desc" => "Dieser Assistent hilft Ihnen beim Aufspüren verlorener oder versehentlich gelöschter Dateien. Damit können sogar Dateien wiederhergestellt werden, nachdem ein Datenträger formatiert wurde. Auch die Suche auf beschädigten Festplatten ist möglich.",
		"assi_title" => "Datenwiederherstellung",
		"drive_sel" => "Wählen Sie das Laufwerk, auf dem Sie die Daten suchen wollen. Falls Sie eine Festplatte umpartitioniert haben oder die Partitionstabelle nicht (mehr) lesbar ist, können Sie die Suche über eine gesamte Platte durchführen. Ansonsten empfehlen wir die Suche auf einer Partition. Achtung: Es werden nur Partitionen und Festplatten angezeigt, die momentan nicht eingebunden sind!",
		"scan_part" => "Auf Partition suchen",
		"scan_disk" => "Auf gesamter Festplatte suchen",
		"scan_title" => "Auswahl des Suchortes",
		"type_sel" => "Wählen Sie die Dateitypen, nach denen gesucht werden soll. Die Suche nach allen Dateitypen bringt oft nicht benötigte Archive und EXE-Dateien zum Vorschein. In den meisten Fällen ist es daher besser, die Suche auf bestimmte Medien- oder Office-Formate einzuschränken.",
		"type_all" => "Alle bekannten Dateitypen suchen",
		"type_only" =>  "Zu suchende Dateitypen auswählen",
		"type_title" => "Auswahl des Datenformate",
		"targ_desc" => "Wählen Sie das Zielverzeichnis aus. In diesem entsteht ein neuer Ordner %TARGET%.1, in dem die gefundenen Dateien abgelegt werden. Bedenken Sie bei der Auswahl des Zielverzeichnisses, dass das gefundene Datenvolumen der Partitionsgröße entsprechen kann!",
		"targ_button" => "Zielverzeichnis wählen",
		"targ_open" => "Nach Datenrettung Zielverzeichnis öffnen",
		"targ_title" => "Auswahl des Zielordners",
		"do_you_want" => "Wollen Sie die Wiederherstellung mit den vorgenommenen Einstellungen durchführen?",
		"last_label" => "Nach einem Klick auf \"Anwenden\" startet die Suche nach Dateien in einem neuen Fenster. Bitte schließen Sie dieses nicht. Am Ende wird eine Zusammenfassung der Wiederherstellung angezeigt.",
		"overview" => "Zusammenfassung",
		"ovlabel" => "<b>Suche auf:</b> %DEVICE%\n\n<b>Suche nach:</b> %SEARCHFOR%\n\n<b>Gefundene Dateien speichern in:</b> %TDIR%/%SUFFIX%.1\n\n<b>Benötigte Zeit:</b> %MINTIME% bis %MAXTIME% Minuten (geschätzt)"
	},
	"en" => {
		"prog_title" => "Data recovery",
		"unknown_fs" => "Unknown file system",
		"no_part_found" => "No suitable partition found for searching files - you might unmount some drives",
		"no_disk_found" => "No suitable disk found for searching files - you might unmount some drives",
		"do_not_close" => "Please do not close!",
		"rec_fin_short" => "Data recovery finished",
		"rec_fin_long" => "The data recovery is completed!",
		"rec_fin_fail" => "No space left in target directory. It is likely that not all files could be recovered!",
		"assi_desc" => "This program helps recovering deleted or lost files. In many cases recovery is possible even after formatting a disk. It also works on damaged hard disks.",
		"assi_title" => "Data recovery",
		"drive_sel" => "Select the drive from which you want to recover files. If you changed the partitioning or the partition table is not readable (anymore), you can start scanning the whole disk. Otherwise we recommend scanning a partition. Important: Only disks and partitions that are not mounted are shown here!",
		"scan_part" => "Scan a partition",
		"scan_disk" => "Scan a whole disk",
		"scan_title" => "Select drive to scan",
		"type_sel" => "Select which file types should be recovered. Scanning for all file types often recovers many EXE and archive files that are not needed anymore. Thus it is recommended to limit the search on certain office and media formats.",
		"type_all" => "Search for all known file types",
		"type_only" =>  "Select file types to search for",
		"type_title" => "Select file types",
		"targ_desc" => "Select the target directory. In this directory a new folder %TARGET%.1 is created that contains the recovered files. When selecting the target folder please keep in mind that the volume of the recovered data can reach the size of the partition scanned.",
		"targ_button" => "Select target directory",
		"targ_open" => "Open target directory after recovery",
		"targ_title" => "Selection of target directory",
		"do_you_want" => "Do you want to start the data recovery with the selected settings?",
		"last_label" => "After clicking \"Apply\" the data recovery starts in a new window. Please do not close this window. When the recovery is finished a log will be shown.",
		"overview" => "Overview",
		"ovlabel" => "<b>Scan drive:</b> %DEVICE%\n\n<b>Search for:</b> %SEARCHFOR%\n\n<b>Save restored files in:</b> %TDIR%/%SUFFIX%.1\n\n<b>Estimated time:</b> %MINTIME% to %MAXTIME% minutes"
	},
	"pl" => {
		"prog_title" => "Odzyskiwanie danych",
                "unknown_fs" => "Nieznany system plików",
                "no_part_found" => "Nie wykryto partycji, na której można wyszukać pliki - być może musisz odmontować napęd(y)",
                "no_disk_found" => "Nie wykryto dysku, na którym można wyszukać pliki - być może musisz odmontować napęd(y)",
                "do_not_close" => "Nie zamykaj tego okna!",
                "rec_fin_short" => "Odzyskiwanie danych zakończone",
                "rec_fin_long" => "Proces odzyskiwania danych został zakończony!",
                "rec_fin_fail" => "Brak miejsca w katalogu docelowym. Prawdopodobnie nie wszystkie pliki zostały odzyskane!",
                "assi_desc" => "Program ten umożliwia odzyskanie skasowanych lub zagubionych plików. W wielu przypadkach jest to możliwe nawet po sformatowaniu dysku. Można także odzyskiwać pliki z uszkodzonych dysków.",
                "assi_title" => "Odzyskiwanie danych",
                "drive_sel" => "Wybierz napęd, z którego chcesz odzyskać pliki. Jeśli zmieniłeś na nim układ partycji, lub tablica partycji nie daje się odczytać, możesz zbadać cały dysk. W innym wypadku wybierz badanie partycji. Ważne: lista zawiera tylko niezamontowane dyski i partycje!",
                "scan_part" => "Zbadaj partycję",
                "scan_disk" => "Zbadaj cały dysk",
                "scan_title" => "Wybierz napęd do zbadania",
                "type_sel" => "Wybierz typy plików, jakie chcesz odzyskać. Badanie wszystkich typów plików często skutkuje odzyskaniem wielu niepotrzebnych plików EXE i archiwów. Dlatego też zalecamy ograniczenie wyszukiwania do niezbędnych plików - np. dokumentów i multimediów.",
                "type_all" => "Wyszukaj wszystkie znane typy plików",
                "type_only" =>  "Wybierz typy plików do znalezienia",
                "type_title" => "Wybierz typy plików",
                "targ_desc" => "Wybierz folder docelowy. Zostanie w nim utworzony podkatalog %TARGET%.1, w którym umieszczone zostaną odzyskane pliki. Przy wybieraniu folderu docelowego weź pod uwagę fakt, że ilość odzyskanych danych może być równa wielkości badanej partycji.",
                "targ_button" => "Wybierz folder docelowy",
                "targ_open" => "Otwórz folder docelowy po zakończeniu odzyskiwania",
                "targ_title" => "Wybór folderu docelowego",
                "do_you_want" => "Czy chcesz rozpocząć odzyskiwanie danych z tymi ustawieniami?",
                "last_label" => "Po kliknięciu \"Zastosuj\" zostanie otwarte nowe okno procesu odzyskiwania danych. Nie zamykaj go! Po zakończeniu odzyskiwania danych zobaczysz plik dziennika zdarzeń.",
                "overview" => "Podsumowanie",
                "ovlabel" => "<b>Badaj napęd:</b> %DEVICE%\n\n<b>Wyszukaj:</b> %SEARCHFOR%\n\n<b>Zapisz odzyskane pliki w:</b> %TDIR%/%SUFFIX%.1\n\n<b>Przybliżony czas:</b> %MINTIME% do %MAXTIME% minutes"
	},
	"es" => {
		"prog_title" => "Recuperación de datos",
                "unknown_fs" => "Archivo de sistema desconocido",
                "no_part_found" => "No se encuentra una partición adecuada para la búsqueda de archivos. Quizá deba desmontar alguna unidad",
                "no_disk_found" => "No se encuentra ningún disco adecuado para la búsqueda de archivos. Quizá deba desmontar alguna unidad",
                "do_not_close" => "Por favor, no cerrar",
                "rec_fin_short" => "Recuperación de datos completa",
                "rec_fin_long" => "La recuperación de datos se ha completado",
                "rec_fin_fail" => "No queda espacio en el directorio de destino. Es posible que no se puedan recuperar todos los archivos.",
                "assi_desc" => "Este programa le ayudará a recuperar los datos borrados o perdidos. En algunos casos es posible recuperarlos incluso después de formatear el disco. También funciona con discos duros dañados.",
                "assi_title" => "Recuperación de datos",
                "drive_sel" => "Seleccione la unidad desde donde quiere recuperar los archivos. Si ha cambiado la partición o la tabla de particiones no es legible, puede comenzar a escanear el disco completo. En caso contrario, se recomienda escanear una partición. Importante: Sólo se mostrarán los discos y las particiones que no están montados",
                "scan_part" => "Explorar una partición",
                "scan_disk" => "Explorar un disco completo",
                "scan_title" => "Seleccionar la unidad a escanear",
                "type_sel" => "Seleccionar qué tipo de archivos podrán ser recuperados. Al explorar todos los tipos de archivo, puede recuperar algunos archivos EXE que no sean necesarios. Por lo tanto, se recomienda limitar la búsqueda de determinados formatos.",
                "type_all" => "Buscar todos los tipos de archivos conocidos",
                "type_only" =>  "Seleccione los tipos de archivos para buscar",
                "type_title" => "Seleccione los tipos de archivos",
                "targ_desc" => "Seleccione el directorio de destino. En este directorio %TARGET%.1 se creará una nueva carpeta para guardar los archivos recuperados. Cuando seleccione el directorio de destino por favor, tenga presente que el volumen de los datos recuperados puede ser mayor que el de la partición escaneada.",
                "targ_button" => "Seleccione el directorio de destino",
                "targ_open" => "Abrir el directorio de destino después de la recuperación",
                "targ_title" => "Selección del directorio de destino",
                "do_you_want" => "¿Desea iniciar la recuperación de datos con los ajustes seleccionados?",
                "last_label" => "Después de pulsar \"Apply\" la recuperación de datos se iniciará en una nueva ventana. Por favor, no cierre esta ventana. Cuando la recuperación se haya completado se mostrará un mensaje de confirmación.",
                "overview" => "Información de destino",
                "ovlabel" => "<b>Unidad de exploración:</b> %DEVICE%\n\n<b>Buscar para:</b> %SEARCHFOR%\n\n<b>Guardar los archivos recuperados en:</b> %TDIR%/%SUFFIX%.1\n\n<b>Tiempo estimado:</b> %MINTIME% a %MAXTIME% minutes"
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


#LANGUAGE = ENV['LANGUAGE'][0..1]

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
target_dir = "/tmp"
targetsuff = Time.now.strftime("photorec_%Y%m%d-%H%M%S")
xml_read_count = 0

def read_suffixes
	suffixes = []
	begin
		File.open("/etc/lesslinux/emergencytools/photorec_suffixes.txt").each { |line|
			# puts line
			suffixes.push(line.strip) if line.strip.length > 0
		}
	rescue
		File.open("photorec_suffixes.txt").each { |line|
			# puts line
			suffixes.push(line.strip) if line.strip.length > 0
		}
	end
	return suffixes
end

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
					begin
						parts.push( [ n.elements["logicalname"].text,
						fstype.to_s,
						state, mount_point, rw, capacity ] )
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

def apply_settings(assi, device, filetypes, target, partition, target_dir, opentarget )
	puts target
	puts target_dir
	partstring = "partition_i386"
	partstring = "partition_none" if partition == true
	fileopt = "enable,"
	if filetypes.size > 0 
		fileopt = "disable,"
		filetypes.each { |f|
			fileopt = fileopt + f + ",enable,"
		}
	end
	phrecstring = "photorec /d \"" + target + "\" /cmd " + device + " " + partstring + ",fileopt,everything," + fileopt + "search"
	if $dummy == true
		puts phrecstring
	else
		system("Terminal --hide-toolbar --hide-menubar --disable-server -T \"" + extract_lang_string("do_not_close") + "\" -x " + phrecstring )
	end
	freespace = 0
	IO.popen("df \"" + target_dir + "\"") { |i|
		while i.gets
			puts $_
			cols = $_.split
			freespace = cols[3].strip.to_i
			puts cols.join("+")
		end
	}
	if freespace > 0
		dialog = Gtk::Dialog.new(extract_lang_string("rec_fin_short"),assi,Gtk::Dialog::MODAL,
			[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
		)
		dialog.has_separator = false
		label = Gtk::Label.new(extract_lang_string("rec_fin_long"))
		label.wrap = true
		image = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
	else
		dialog = Gtk::Dialog.new(extract_lang_string("rec_fin_short"),assi,Gtk::Dialog::MODAL,
			[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
		)
		dialog.has_separator = false
		label = Gtk::Label.new(extract_lang_string("rec_fin_fail"))
		label.wrap = true
		image = Gtk::Image.new(Gtk::Stock::DIALOG_WARNING, Gtk::IconSize::DIALOG)
	end
	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image);
	hbox.pack_start_defaults(label);

	dialog.vbox.add(hbox)
	dialog.show_all
	dialog.run
	dialog.destroy
	system("chown -R surfer \"" + target + ".1\"")
	# assi.destroy
	system("su surfer -c 'exo-open \"" + target + ".1\"'") if opentarget == true
	puts "Alles hat ein Ende!"
	assi.destroy
end

#========================================
# First window - tell the user what we do
#========================================

desclabel = Gtk::Label.new(extract_lang_string("assi_desc"))
desclabel.wrap = true
desclabel.width_request = 550
desclabel.xalign = 0.1

descpage = assi.append_page(desclabel)
assi.set_page_title(desclabel, extract_lang_string("assi_title") )
assi.set_page_type(desclabel, Gtk::Assistant::PAGE_CONTENT)
assi.set_page_complete(desclabel, true) # false)

#========================================
# Second window - choose the partition
#========================================

partlabel = Gtk::Label.new(extract_lang_string("drive_sel"))
partlabel.wrap = true
partlabel.width_request = 550
partlabel.xalign = 0.1

partbox = Gtk::VBox.new(false, 5)
partbox.pack_start(partlabel, false, true, 5)

partradio = Gtk::RadioButton.new(extract_lang_string("scan_part"))
partcombo = Gtk::ComboBox.new
# partcombo.append_text("/dev/sda1 Hulla")
# partcombo.append_text("/dev/sdb9 Bulla")
# partcombo.active = 0
partrows = 0
partbox.pack_start(partradio, false, true, 5)
partbox.pack_start(partcombo, false, true, 5)
diskradio = Gtk::RadioButton.new(partradio, extract_lang_string("scan_disk"))
diskcombo = Gtk::ComboBox.new
# diskcombo.append_text("/dev/sda Hulla")
# diskcombo.append_text("/dev/sdb Bulla")
# diskcombo.active = 0
diskrows = 0
diskcombo.sensitive = false
partbox.pack_start(diskradio, false, true, 5)
partbox.pack_start(diskcombo, false, true, 5)

partradio.signal_connect("clicked") { |b|
	diskcombo.sensitive = false
	partcombo.sensitive = true
}

diskradio.signal_connect("clicked") { |b|
	partcombo.sensitive = false
	diskcombo.sensitive = true
}

partpage = assi.append_page(partbox)
assi.set_page_title(partbox, extract_lang_string("scan_title"))
assi.set_page_type(partbox, Gtk::Assistant::PAGE_CONTENT)
assi.set_page_complete(partbox, false)

#========================================
# Third window - choose filetypes to save
#========================================

typelabel = Gtk::Label.new(extract_lang_string("type_sel"))
typelabel.wrap = true
typelabel.width_request = 550
typelabel.xalign = 0.1

typeradio = Gtk::RadioButton.new(extract_lang_string("type_all"))
typeselec = Gtk::RadioButton.new(typeradio, extract_lang_string("type_only"))
typebox = Gtk::VBox.new(false, 5)
typebox.pack_start(typelabel, false, true, 5)
typebox.pack_start(typeradio, false, true, 5)
typebox.pack_start(typeselec, false, true, 5)

scroll_pane = Gtk::ScrolledWindow.new
scroll_pane.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)

scrollbox = Gtk::VBox.new(false, 5)

checks = []
# formats = [ "doc", "xls", "jpg", "png", "abc", "cde", "ppt", "exif", "html", "h", "c", "c++", "d", "e" ]
formats = read_suffixes
format_checkboxes = []
formats.each { |f|
	checkme = Gtk::CheckButton.new(f)
	format_checkboxes.push(checkme)
	scrollbox.pack_start(checkme, false, true, 0)
}

scroll_pane.add_with_viewport(scrollbox)
scroll_pane.sensitive = false
typebox.pack_start(scroll_pane, true, true, 5)

typeselec.signal_connect("clicked") { |b| scroll_pane.sensitive = true }
typeradio.signal_connect("clicked") { |b| scroll_pane.sensitive = false }

typepage = assi.append_page(typebox)
assi.set_page_title(typebox, extract_lang_string("type_title") )
assi.set_page_type(typebox, Gtk::Assistant::PAGE_CONTENT)
assi.set_page_complete(typebox, true) # false)

#========================================
# Fourth window - choose taget directory
#========================================

targlabel = Gtk::Label.new(extract_lang_string("targ_desc").gsub("%TARGET%", targetsuff))
targlabel.wrap = true
targlabel.width_request = 550
targlabel.xalign = 0.1

chooser_dir  = Gtk::FileChooserButton.new(extract_lang_string("targ_button"), Gtk::FileChooser::ACTION_SELECT_FOLDER)

opentarget = Gtk::CheckButton.new(extract_lang_string("targ_open"))
opentarget.active = true

targbox = Gtk::VBox.new(false, 5)
targbox.pack_start(targlabel, false, true, 5)
targbox.pack_start(chooser_dir, false, true, 5)
targbox.pack_start(opentarget, false, true, 5)

targpage = assi.append_page(targbox)
assi.set_page_title(targbox, extract_lang_string("targ_button") )
assi.set_page_type(targbox, Gtk::Assistant::PAGE_CONTENT)
assi.set_page_complete(targbox, false)

chooser_dir.signal_connect('selection_changed') do |w|
  puts w.filename
  target_dir = w.filename
  assi.set_page_complete(targbox, true)
end

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

lastdesc = Gtk::Label.new(extract_lang_string("last_label"))
lastdesc.wrap = true
lastdesc.width_request = 550
lastdesc.xalign = 0.1

lastbox = Gtk::VBox.new(false, 5)
lastbox.pack_start(lastlabel, false, true, 5)
lastbox.pack_start(ovlabel, false, true, 5)
lastbox.pack_start(lastdesc, false, true, 5)

lastpage = assi.append_page(lastbox)
assi.set_page_title(lastbox, extract_lang_string("overview") )
assi.set_page_type(lastbox, Gtk::Assistant::PAGE_CONFIRM)
assi.set_page_complete(lastbox, true)

#========================================
# Common settings and callbacks
#========================================

assi.set_title extract_lang_string("data_recovery")
assi.border_width = 10
assi.set_size_request(600, 410)
assi.signal_connect('destroy') { Gtk.main_quit }
assi.signal_connect('cancel')  { assi.destroy }
assi.signal_connect('close')   { |w| 
	puts niceparts[partcombo.active]
	puts nicedrives[diskcombo.active]
	puts partsizes[partcombo.active]
	puts drivesizes[diskcombo.active]
	puts partarray[partcombo.active]
	puts diskarray[diskcombo.active]
	puts partradio.active?
	puts typeradio.active?
	searchformats = []
	formatcount = 0
	format_checkboxes.each { |c|
		searchformats.push(formats[formatcount]) if c.active?
		formatcount += 1
	}
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
	else
		scantypes = searchformats 
	end
	apply_settings(w, scandev, scantypes, target_dir + "/" + targetsuff, partradio.active?, target_dir, opentarget.active?)
}

assi.set_forward_page_func{|curr|
	searchformats = []
	formatcount = 0
	format_checkboxes.each { |c|
		searchformats.push(formats[formatcount]) if c.active?
		formatcount += 1
	}
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
		searchfor = extract_lang_string("type_all")
	else
		scantypes = searchformats
		searchfor = extract_lang_string("type_only")
	end
	maxtime = scansize.to_i / 400_000_000
	mintime = scansize.to_i / 2_000_000_000
	# "<b>Suche auf:</b> %DEVICE%\n\n<b>Suche nach:</b> %SEARCHFOR%\n\n<b>Gefundene Dateien speichern in:</b> %TDIR%/%SUFFIX%.1\n\n<b>Benötigte Zeit:</b> %MINTIME% bis %MAXTIME% Minuten (geschätzt)"
	begin
		ovlabel.set_markup(extract_lang_string("ovlabel").gsub("%DEVICE%", nicedev.to_s).gsub("%SEARCHFOR%", searchfor).
			gsub("%TDIR%", target_dir).gsub("%SUFFIX%", targetsuff).gsub("%MINTIME%", mintime.to_i.to_s).
			gsub("%MAXTIME%", maxtime.to_i.to_s))
	rescue
	end
	puts curr
	if curr == 0
		# when switching from first to second screen, read drivelist
		puts "current screen 0, rereading drivelist"
		alldisks = scan_parts(read_devs) if xml_read_count < 1
		xml_read_count += 1
		alldisks.each { |d|
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
			# puts " -+- " + d[5][0][6].to_s + " -+-"
		}
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
