#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
require "rexml/document"

# constants for localization

LANGUAGE = ENV['LANGUAGE'][0..1]
LOCSTRINGS = {
	"de" => {
		"screen_1_title" => "Installation",
		"screen_1" => "Installieren Sie %BRANDLONG% auf einen USB-Speicherstift. Stecken Sie dazu jetzt den Stift ein. Andere eventuell angeschlossene USB-Laufwerke müssen Sie entfernen.",
		"screen_2_title" => "Auswahl des Installationsziels",
		"screen_2" => "Auf welches USB-Laufwerk wollen Sie %BRANDLONG% installieren? Das ausgewählte Laufwerk wird komplett gelöscht. Falls mehrere Laufwerke angezeigt werden, können Sie einen Schritt zurück gehen und die nicht als Installationsziel vorgesehenen Laufwerke abziehen.",
		"screen_2_size" => "Soviel Speicherplatz wird nach der Installation auf Ihrem Speicherstift von System (512MB) und Datentresor (Rest) belegt sein:",
		"screen_2_expl" => "In diesem Bereich liegen System und Datentresor. Mit  Windows können Sie darauf nicht zugreifen. Falls Sie viele vertrauliche Daten auf dem Stift speichern, können Sie den dafür reservierten Bereich größer wählen.",
		"screen_3_contdesc" => "Ein verschlüsselter Datentresor erlaubt es Ihnen, Einstellungen, Lesezeichen oder Daten dauerhaft zu sichern. Wenn Sie einen Datentresor anlegen, werden bei jedem Start von %BRANDLONG% nach dem Passwort für diesen Tresor gefragt.",
		"screen_3_container" => "Ich will einen Datentresor für Einstellungen und Lesezeichen anlegen",
		"screen_3" => "Mit dem folgenden Passwort können Sie künftig beim Start von %BRANDLONG% auf Ihren Datentresor zugreifen.",
		"screen_3_user" => "Hier können Sie ein zusätzliches Passwort eingeben, das beim Zugriff auf Laufwerke abgefragt wird. Falls Sie die Felder leer lassen, wird automatisch das oben vergebene verwendet. Sie erhöhen die Sicherheit, wenn Sie verschiedene Passwörter vergeben.",
		"install_wait" => "Die Installation läuft. Bitte haben Sie etwas Geduld!",
		"install_start" => "Start der Installation: Erzeuge Passwort",
		"install_partition" => "Passwort erzeugt - Partitionierung",
		"install_bootloader" => "Partitionierung abgeschlossen - Schreibe Bootloader",
		"install_system" => "Bootloader geschrieben - Kopiere System",
		"install_crypt" => "System kopiert - erstelle Datentresor",
		"install_finished" => "Installation abgeschlossen",
		"install_finished_long" => "Die Installation ist abgeschlossen, klicken Sie auf OK, um den Computer neu zu starten.",
		"password_explanation" => "Das Passwort muss wenigstens zehn Zeichen lang sein und mindestens einen Klein-, einen Großbuchstaben sowie eine Zahl enthalten.",
		"password" => "Passwort:",
		"password_confirm" => "Bestatigung:",
		"password_title" => "Datentresor",
		"confirm_install" => "Klicken Sie auf \"Anwenden\" um die Installation mit den vorgenommenen Einstellungen zu starten. Alle Daten auf dem ausgewählten Laufwerk werden dabei gelöscht.",
		"confirm_check" => "Ja, Datenträger löschen und %BRANDLONG% installieren",
		"ready_to_install" => "Bereit zur Installation"
	},
	"en" => {
		"screen_1_title" => "Installation",
		"screen_1" => "Install %BRANDLONG% on a USB thumb drive. Please connect the drive now and revome other connected USB drives.",
		"screen_2_title" => "Installation target",
		"screen_2" => "Please choose the installation target:",
		"screen_2_size" => "Choose the space occupied by %BRANDLONG%:",
		"screen_2_expl" => "This area is used to store the system and your encrypted container. It is not accessible from Windows. If you intend to store many files you might choose a larger value.",
		"screen_3" => "Choose a password that is used to unlock the encrypted container when starting %BRANDLONG%.",
		"screen_3_contdesc" => "An encrypted container allows to permanently store settings, files and bookmarks. If you decide to create a container, %BRANDLONG% will ask you for the container's password at every startup.",
		"screen_3_container" => "I want to create an encrypted container for storing settings",
		"screen_3_user" => "You can increase the security by choosing a diffent password for access to drives. If you do not fill out these fields, the password chosen above will be used.",
		"install_wait" => "The installation is in progress. Please be patient!",
		"install_start" => "Beginning of installation: Create password",
		"install_partition" => "Password created - Partition target drive",
		"install_bootloader" => "Partitioning finished - Write bootloader",
		"install_system" => "Bootloader written - Copy system",
		"install_crypt" => "System copied - Create encrypted container",
		"install_finished" => "Installation finished",
		"install_finished_long" => "The installation is finished, please click OK to reboot the computer.",
		"password_explanation" => "The password length is ten characters minumum. It must contain numbers, uppercase and lowercase letters.",
		"password" => "Password:",
		"password_confirm" => "Confirmation:",
		"password_title" => "Encrypted Container",
		"confirm_install" => "Click \"Apply\" to start the installation using the choices you made. All files on the selected installation drive will be deleted.",
		"confirm_check" => "Yes, delete the selected drive and install %BRANDLONG%",
		"ready_to_install" => "Ready to install"
	},
	"es" => {
                "screen_1_title" => "Instalación",
                "screen_1" => "Instala %BRANDLONG% en un pendrive. Por favor, conecta ahora el dispositivo y quita otras memorias USB que estén conectadas.",
                "screen_2_title" => "Directorio de instalación",
                "screen_2" => "Por favor, elige el directorio de instalación:",
                "screen_2_size" => "Elige el espacio ocupado por %BRANDLONG%:",
                "screen_2_expl" => "Esta área se usa como almacenaje del sistema y de tus datos cifrados. No es accesible desde Windows. Si pretendes almacenar más ficheros puedes elegir un valor más largo.",
                "screen_3" => "Elige una contraseña para abrir el contenedor de archivos cifrados al iniciar %BRANDLONG%.",
                "screen_3_contdesc" => "Un contenedor cifrado permite almacenar configuraciones, archivos y marcadores de forma permanente. Si decides crear un fichero, %BRANDLONG% te preguntará por la contraseña del mismo siempre que inicies.",
                "screen_3_container" => "Quiero crear un contenedor cifrado para almacenar las configuraciones",
                "screen_3_user" => "Puedes aumentar la seguridad estableciendo una contraseña diferente para acceder a las unidades de disco. Si no rellenas estos campos se empleará la contraseña arriba indicada.",
                "install_wait" => "Instalación en proceso. Por favor, espera",
                "install_start" => "Comenzando la instalación: Creación de contraseña",
                "install_partition" => "Contraseña creada - Particionando el disco de destino",
                "install_bootloader" => "Partición creada - Escribiendo el gestor de arranque",
                "install_system" => "Gestor de arranque escrito - Copiando el sistema",
                "install_crypt" => "Sistema copiado - Creando contenedor cifrado",
                "install_finished" => "Instalación finalizada",
                "install_finished_long" => "La instalación ha finalizado, por favor presiona OK para reiniciar el ordenador.",
                "password_explanation" => "La extensión mínima de la contraseña es de diez caracteres. Debe incluir números, mayúsculas y minúsculas.",
                "password" => "Contraseña:",
                "password_confirm" => "Confirma contraseña:",
                "password_title" => "Contenedor cifrado",
                "confirm_install" => "Presiona \"Aplicar\" para iniciar la instalación de las opciones predeterminadas. AVISO: ¡Todos los ficheros existentes en el disco serán borrados!",
                "confirm_check" => "Sí, borrar la unidad seleccionada e instalar %BRANDLONG%",
                "ready_to_install" => "Preparado para instalar"
        },
	"ru" => {
                "screen_1_title" => "Установка",
                "screen_1" => "Установка %BRANDLONG% на флэш-накопитель. Подключите флэшку и убедитесь, что другие USB-накопители отключены.",
                "screen_2_title" => "Место установки",
                "screen_2" => "Выберите накопитель для установки:",
                "screen_2_size" => "Укажите размер области, выделяемой под %BRANDLONG%:",
                "screen_2_expl" => "Эта область будет использована для хранения системы и зашифрованного контейнера. Она будет недоступна из Windows. Если вам потребуется место для новых файлов, вы можете изменить размер области.",
                "screen_3" => "Укажите пароль, который будет использоваться для доступа к контейнеру после запуска %BRANDLONG%.",
                "screen_3_contdesc" => "В зашифрованном контейнере можно хранить настройки, файлы и закладки. Если вы решили создать контейнер, %BRANDLONG% будет запрашивать у вас пароль при каждой загрузке.",
                "screen_3_container" => "Я хочу создать зашифрованный контейнер для хранения параметров",
                "screen_3_user" => "Чтобы усилить степень защиты, используйте различные пароли для доступа к устройствам. Если вы не заполните эти поля, пароль останется прежним.",
                "install_wait" => "Идет установка. Подождите!",
                "install_start" => "Начало установки: создание пароля",
                "install_partition" => "Создание пароля - Идет создание раздела на указанном устройстве",
                "install_bootloader" => "Создание раздела завершено - Идет запись загрузчика",
                "install_system" => "Загрузчик создан - Идет копирование системы",
                "install_crypt" => "Система скопирована - Идет создание зашифрованного контейнера",
                "install_finished" => "Завершение установки",
                "install_finished_long" => "Установка завершена, нажмите OK для перезагрузки системы.",
                "password_explanation" => "Длина пароля - минимум 10 символов. Он должен содержать цифры, заглавные и строчные буквы.",
                "password" => "Пароль:",
                "password_confirm" => "Подтверждение пароля:",
                "password_title" => "Зашифрованный контейнер",
                "confirm_install" => "Нажмите на \"Применить\" для запуска установки с выбранными параметрами. Все файлы на выбранном устройстве будут удалены.",
                "confirm_check" => "Да, удалить все файлы на выбранном устройстве и установить %BRANDLONG%",
                "ready_to_install" => "Готов к установке"
        },
	"pl" => {
                "screen_1_title" => "Instalacja",
                "screen_1" => "Zainstaluj %BRANDLONG% na nośniku USB. Podłącz wybrany nośnik i usuń inne podłączone nośniki USB.",
                "screen_2_title" => "Nośnik docelowy",
                "screen_2" => "Wybierz nośnik docelowy:",
                "screen_2_size" => "Wybierz, ile miejsca przeznaczyć na %BRANDLONG%:",
                "screen_2_expl" => "Przestrzeń ta będzie zawierać system i pojemnik zaszyfrowany. Nie będzie dostępna z poziomu Windows. Jeśli planujesz przechowywać tu wiele plików, wybierz większą wartość.",
                "screen_3" => "Wybierz hasło dostępu do pojemnika zaszyfrowanego; będziesz je podawać przy uruchamianiu %BRANDLONG%.",
                "screen_3_contdesc" => "Pojemnik zaszyfrowany pozwala na przechowywanie ustawień, plików i zakładek. Jeśli utworzysz pojemnik, przy każdym uruchomieniu %BRANDLONG% będzie pytał o hasło dostępu do pojemnika.",
                "screen_3_container" => "Chcę utworzyć pojemnik zaszyfrowany do przechowywania ustawień itp.",
                "screen_3_user" => "Większy poziom bezpieczeństwa uzyskasz, jeśli wybierzesz inne hasło dostępu do dysków. Jeśli nie wypełnisz poniższych pól, hasło dostępu do dysków będzie takie, jak wpisane powyżej.",
                "install_wait" => "Trwa instalacja. Uzbrój się w cierpliwość!",
                "install_start" => "Rozpoczynanie instalacji: Tworzenie haseł",
                "install_partition" => "Hasła utworzone - Partycjonowanie dysku",
                "install_bootloader" => "Koniec partycjonowania - Zapis bootloadera",
                "install_system" => "Bootloader zapisany - Kopiowanie systemu",
                "install_crypt" => "System skopiowany - Tworzenie pojemnika zaszyfrowanego",
                "install_finished" => "Instalacja zakończona",
                "install_finished_long" => "Proces instalacji został zakończony. Kliknij OK aby ponownie uruchomić komputer.",
                "password_explanation" => "Minimalna długość hasła to 10 znaków. Musi ono zawierać cyfry oraz wielkie i małe litery.",
                "password" => "Hasło:",
                "password_confirm" => "Powtórz hasło:",
                "password_title" => "Pojemnik zaszyfrowany",
                "confirm_install" => "Kliknij \"Zastosuj\" aby uruchomić instalację przy użyciu wybranych ustawień. Wszystkie pliki na wybranym nośniku zostaną usunięte.",
                "confirm_check" => "Tak, skasuj zawartość nośnika i zainstaluj %BRANDLONG%",
                "ready_to_install" => "Gotowy do instalacji"
        },
}

@xbranding = File.new( "/etc/lesslinux/branding/branding.xml" )
@branding = REXML::Document.new  @xbranding

def get_brandlong
	root = @branding.root
	lang = "en"
	brandlong =  root.elements["strings[@lang='" + lang + "']/brandstr[@id='brandlong']"].text
	lang = LANGUAGE unless LANGUAGE.nil?
	begin 
		brandlong =  root.elements["strings[@lang='" + lang + "']/brandstr[@id='brandlong']"].text
	rescue
	end
	return brandlong
end

def get_brandshort
	root = @branding.root
	return root.elements["brandshort"].text.strip
end

def get_minsize
	root = @branding.root
	minsize = 900_000_000
	begin
		minsize = root.elements["installer/minsize"].text.strip.to_i
	rescue
	end
	return minsize
end

def get_systemsize
	root = @branding.root
	syssize = 600_000_000
	begin
		syssize = root.elements["installer/syssize"].text.strip.to_i
	rescue
	end
	return syssize
end

def get_partminimum
	root = @branding.root
	partminimum = 1_900_000_000
	begin
		partminimum = root.elements["installer/partminimum"].text.strip.to_i
	rescue
	end
	return partminimum
end

def get_force_single_part
	root = @branding.root
	begin
		if root.elements["installer/forcesinglepart"].text.strip =~ /true/
			return true
		end
	rescue
		return false
	end
	return false
end

def get_force_nocontainer
	root = @branding.root
	begin
		if root.elements["installer/forcenocontainer"].text.strip =~ /true/
			return true
		end
	rescue
		return false
	end
	return false
end

def get_additional_dirs
	root = @branding.root
	additional_dirs = []
	begin
		root.elements.each("installer/additionaldirs/dir") { |d|
			additional_dirs.push(d.text.strip)
		}
	rescue
	end
	return additional_dirs
end

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
	return message_string.gsub('%BRANDLONG%', get_brandlong)
end


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
		if val.size > get_minsize
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

def adjust_size_spinner(spinbox, selected_item, drivelist)
	size = 0
	megsize = 0
	begin
		size = drivelist[selected_item].size
		megsize = size / 1048576
		puts "selected size: " + size.to_s
	rescue
		spinbox.sensitive = false
		return
	end
	# Allow partitioning only on drives 2GB and up
	if get_force_nocontainer == true
		spinbox.value = (get_systemsize / 1024).to_i  
		spinbox.sensitive = false
	elsif size > get_partminimum && get_force_single_part == false
		maxsize = megsize - 512
		# maxsize = 4600 if maxsize > 4600 
		spinbox.adjustment = Gtk::Adjustment.new(1024, 1024, maxsize, 64, 1.0, 1.0)
		spinbox.value = 1024
		spinbox.sensitive = true
	else
		spinbox.adjustment = Gtk::Adjustment.new(megsize, megsize, megsize, 64, 1.0, 1.0)
		spinbox.value = megsize
		spinbox.sensitive = false
	end
	
end

def password_compare(cont_pw, cont_conf, user_pw, user_conf)
	if user_pw.size == 0 && user_conf.size == 0
		return cont_pw == cont_conf && check_pw_policy(cont_pw)
	else
		return cont_pw == cont_conf && user_pw == user_conf && check_pw_policy(cont_pw) && check_pw_policy(user_pw)
	end
	return false
end

def check_pw_policy(password) 
	unless LANGUAGE == "pl" || LANGUAGE == "ru"
		return password.size > 9 && password =~ /[A-Z]/ && password =~ /[a-z]/ && password =~ /[0-9]/
	else
		return password.size > 9 && password =~ /[0-9]/
	end
end

def create_pwhash(pw)
	puts("== Replace password hash ==")
	# puts pw
	system(	"echo -n '" + pw.gsub("'", "\\\\" + '\'') + "' | openssl passwd -1 -stdin > /etc/lesslinux/surfer.hash") 
	system( "/etc/rc.d/0040-roothash.sh start")
end

def run_partitioning(usable_drives, target, syssize)
	puts("== Change partitioning ==")
	selected_drive = usable_drives[target]
	device =  selected_drive.device
	# drive size is in bytes!
	drive_size = selected_drive.size
	# now delete all existing partitions
	# ... the soft way -- does not always work
	# 7.downto(0) { |p| system("parted -s " + device + " rm " + p.to_s) }
	# ... the hard way
	system("dd if=/dev/zero bs=1M count=1 of=" + device)
	system("parted -s " + device + " mklabel msdos")
	system("mdev -s")
	# all further calculations in kilobytes!
	part_two_end = (drive_size.to_i / 1024) - 4096
	part_two_start = part_two_end - syssize.to_i * 1024
	part_one_end = part_two_start - 2048
	part_one_start = 63
	# if device is too small, just create one partition
	# else create two partitions
	if drive_size > get_partminimum && get_force_single_part == false
		system("parted -s " + device + " unit kB mkpartfs primary fat32 " + part_one_start.to_s + " " + part_one_end.to_s)
		# system("parted -s " + device + " unit kB mkpartfs primary fat32 " + part_two_start.to_s + " " + part_two_end.to_s)
		system("parted -s " + device + " unit kB mkpart primary ext2 " + part_two_start.to_s + " " + part_two_end.to_s)
		system("parted -s " + device + " set 2 boot on ")
		system("mdev -s")
		system("mkfs.ext3 " + device + "2")
		system("mdev -s")
		return 2
	else
		system("parted -s " + device + " unit kB mkpartfs primary fat32 " + part_one_start.to_s + " " + part_two_end.to_s)
		system("parted -s " + device + " set 1 boot on ")
		system("mdev -s")
		system("mkfs.msdos -F32 " + device + "1")
		system("mdev -s")
		return 1
	end
end

def write_bootloader(target_stick, part)
	puts("== Write bootloader ==")
	system("mdev -s")
	system("cat /usr/share/syslinux/mbr.bin > " + target_stick)
	system("mkdir /lesslinux/install_target")
	if part > 1
		system("mount -t ext3 " + target_stick + part.to_s + " /lesslinux/install_target")
		system("extlinux -i /lesslinux/install_target")
		system("umount /lesslinux/install_target")
	else
		system("mount -t vfat " + target_stick + part.to_s + " /lesslinux/install_target")
		system("extlinux -i /lesslinux/install_target")
		system("umount /lesslinux/install_target")
	end
end

def run_containercopy(target_stick, part)
	puts("== Copy containers ==")
	system("mdev -s")
	# find out if install source is still mounted
	unless system("mount | awk '{print $1}' | grep ` cat /var/run/lesslinux/install_source ` ")
		system("mount ` cat /var/run/lesslinux/install_source ` /lesslinux/cdrom")
	end
	localsource = "/lesslinux/cdrom/"
	if system("grep 'bootmode=loop' /var/run/lesslinux/startup_vars")
		localsource = "/lesslinux/isoloop/"
	end
	if part > 1
		system("mount -t ext3 " + target_stick + part.to_s + " /lesslinux/install_target")
	else
		system("mount -t vfat " + target_stick + part.to_s + " /lesslinux/install_target")
	end
	[ "syslinux.cfg", "boot", "lesslinux", "GPL.txt" ].each { |e|
		system("/bin/tar -C " + localsource + "  -cf - " + e + " | /bin/tar -C  /lesslinux/install_target -xvf - ")
	}
	# Copy additional dirs
	get_additional_dirs.each { |dir|
		system("/bin/tar -C " + localsource + "  -cf - \"" + dir + "\" | /bin/tar -C  /lesslinux/install_target -xvf - ")
	}
	system("cp /lesslinux/install_target/syslinux.cfg /lesslinux/install_target/extlinux.conf")
	# system("cp /etc/lesslinux/updater/version.txt /lesslinux/install_target")
	run_modscripts(target_stick, part)
	system("umount /lesslinux/install_target")
	system("umount /lesslinux/cdrom")
	system("umount " + target_stick + part.to_s)
end

def run_modscripts(target_device, target_partition)
	Dir.foreach("/etc/lesslinux/installer.d") { |f|
		if f =~ /\.sh$/
			system("bash /etc/lesslinux/installer.d/" + f + " " + target_device + " " +  target_partition.to_s )
		end
		if f =~/\.rb$/
			system("ruby /etc/lesslinux/installer.d/" + f + " " + target_device + " " +  target_partition.to_s )
		end
	}
end

def copy_autorun(target_stick)
	puts("== Copy autorun.inf ==")
	system("mount -t vfat " + target_stick + "1 /lesslinux/install_target")
	# find out if install source is still mounted
	unless system("mount | awk '{print $1}' | grep ` cat /var/run/lesslinux/install_source ` ")
		system("mount ` cat /var/run/lesslinux/install_source ` /lesslinux/cdrom")
	end
	localsource = "/lesslinux/cdrom/"
	if system("grep 'bootmode=loop' /var/run/lesslinux/startup_vars")
		localsource = "/lesslinux/isoloop/"
	end
	system("cp " + localsource + "llicon.ico /lesslinux/install_target")
	system("cp " + localsource + "autorun.usb /lesslinux/install_target/autorun.inf")
	system("umount /lesslinux/cdrom")
	system("umount /lesslinux/install_target")
end

def run_create_crypt(target_stick, part, syssize, pw)
	puts("== Create crypt container ==")
	system("/sbin/modprobe -v dm-crypt")
	system("/sbin/modprobe -v sha256")
	system("mdev -s")
	containersize = syssize - ( get_systemsize / 1_000_000 )
	if part > 1
		system("mount -t ext3 " + target_stick + part.to_s + " /lesslinux/install_target")
	else
		system("mount -t vfat " + target_stick + part.to_s + " /lesslinux/install_target")
	end
	system("dd if=/dev/zero bs=1M count=1 seek=" + (containersize - 1).to_i.to_s + " of='/lesslinux/install_target/" + get_brandshort + ".llc' " )
	# attach loop device to the container
	system("mdev -s")
	free_loop = "/dev/loop9999" # nil
	IO.popen("losetup -f") { |i| 
		while i.gets
			free_loop = $_.to_s.strip
		end
	}
	system("losetup " + free_loop + " '/lesslinux/install_target/" + get_brandshort + ".llc' ")
	system("mdev -s")
	system("dd if=/dev/urandom of=" + free_loop + " bs=1M count=16")
	system("echo '" + pw.gsub("'", "\\\\" + '\'') + "' | cryptsetup luksFormat -c aes-cbc-essiv:sha256 -s 256 -q " + free_loop ) 
	# open the container
	system("echo '" + pw.gsub("'", "\\\\" + '\'') + "' | cryptsetup luksOpen -q " + free_loop + " lesslinux_crypt" ) 
	system("mdev -s")
	system("mkfs.ext3 /dev/mapper/lesslinux_crypt")
	system("mkdir  /lesslinux/tmp_home")
	system("mount -t ext3 /dev/mapper/lesslinux_crypt /lesslinux/tmp_home")
	system("rsync -avHP /home/ /lesslinux/tmp_home/")
	system("mkdir -m 0755 -p /lesslinux/tmp_home/.overlay/etc")
	system("rsync -avHP /etc/shadow /lesslinux/tmp_home/.overlay/etc")
	system("rsync -avHP /etc/passwd /lesslinux/tmp_home/.overlay/etc")
	system("umount /lesslinux/tmp_home/")
	system("cryptsetup luksClose /dev/mapper/lesslinux_crypt")
	system("losetup -d " + free_loop)
	system("umount /lesslinux/install_target")
	# system("sleep 5")
end
	
def run_installation (parent, usable_drives, target, syssize, contpass, userpass, usecontainer)
	puts "Installation target: " + usable_drives[target].device
	puts "Syssize: " + syssize.to_i.to_s
	align = Gtk::Alignment.new(0.5, 0.5, 1.0, 0.0)
	pbar = Gtk::ProgressBar.new
	align.add(pbar)
	dialog = Gtk::Dialog.new(
		"Installationsfortschritt",
		parent,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.vbox.add(align)
	msg = Gtk::Label.new(extract_lang_string("install_wait"))
	msg.wrap = true
	dialog.vbox.add(msg)
	dialog.set_size_request(450, 150)
	dialog.deletable = false
	dialog.show_all
	show_progress(pbar, dialog, msg, usable_drives, target, syssize, contpass, userpass, usecontainer )
	dialog.signal_connect('response') { 
		puts "trigger reboot here..."
		trigger_reboot
		Gtk.main_quit 
	}
end

def show_progress (progress, dialog, msg, usable_drives, target, syssize, contpass, userpass, usecontainer )
	userpass = contpass if userpass.size == 0
	syspartsize = syssize 
	syspartsize = get_systemsize / 1_000_000 if usecontainer == false
	percent = 0.0
	dialog.set_response_sensitive(Gtk::Dialog::RESPONSE_OK, false)
	# button.sensitive = false;

	progress.text = extract_lang_string("install_start")
	progress.fraction = 0.02
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	create_pwhash(userpass)
	
	progress.text = extract_lang_string("install_partition")
	progress.fraction = 0.07
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	target_partition = run_partitioning(usable_drives, target, syspartsize)
	
	progress.text = extract_lang_string("install_bootloader")
	progress.fraction = 0.15
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	write_bootloader(usable_drives[target].device, target_partition)
	
	progress.text = extract_lang_string("install_system")
	progress.fraction = 0.30
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	run_containercopy(usable_drives[target].device, target_partition)
	
	progress.text = extract_lang_string("install_crypt")  if usecontainer == true
	progress.fraction = 0.70
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	run_create_crypt(usable_drives[target].device, target_partition, syssize, contpass)  if usecontainer == true
	copy_autorun(usable_drives[target].device)
	
	progress.text = extract_lang_string("install_finished")
	progress.fraction = 1.00
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	msg.text = extract_lang_string("install_finished_long")
	dialog.set_response_sensitive(Gtk::Dialog::RESPONSE_OK, true)
end

def trigger_reboot
	system("/static/sbin/reboot")
end

assi = Gtk::Assistant.new
assi.deletable = false

usbdrives = nil
usable_drives = []

# Erstes Fenster, Start hat immer ID 0

desclabel = Gtk::Label.new(extract_lang_string("screen_1"))
desclabel.wrap = true
dtid = assi.append_page(desclabel)
assi.set_page_title(desclabel, extract_lang_string("screen_1_title"))
assi.set_page_type(desclabel, Gtk::Assistant::PAGE_INTRO)
assi.set_page_complete(desclabel, true)

# Zweites Fenster, Auswahl des Laufwerkes, Partitionierung

choicelabel = Gtk::Label.new(extract_lang_string("screen_2"))
choicebox = Gtk::ComboBox.new
partlabel = Gtk::Label.new(extract_lang_string("screen_2_size"))
partexpl = Gtk::Label.new(extract_lang_string("screen_2_expl"))
partsize = Gtk::SpinButton.new(1024, 9999999999, 10)
contcheck = Gtk::CheckButton.new(extract_lang_string("screen_3_container"))
choicebox.signal_connect('changed') {
	adjust_size_spinner(partsize, choicebox.active, usable_drives)
	partsize.sensitive = false if contcheck.active? == false
}
choice_vbox = Gtk::VBox.new(false, 5) 
choice_vbox.pack_start(choicelabel, false, true, 5) 
choice_vbox.pack_start(choicebox, false, true, 5) 
# choice_vbox.pack_start(partlabel, false, true, 5) 
# choice_vbox.pack_start(partsize, false, true, 5) 
# choice_vbox.pack_start(partexpl, false, true, 5) 
choicelabel.wrap = true
choicelabel.width_request = 450
choicelabel.xalign = 0.1
partlabel.wrap = true
partlabel.width_request = 550
partlabel.xalign = 0.1
partexpl.wrap = true
partexpl.xalign = 0.1
partexpl.width_request = 550
choiceid = assi.append_page(choice_vbox)
assi.set_page_title(choice_vbox, extract_lang_string("screen_2_title"))
assi.set_page_type(choice_vbox, Gtk::Assistant::PAGE_CONTENT)
assi.set_page_complete(choice_vbox, false)

# Drittes Fenster: Passwörter

contdesc = Gtk::Label.new(extract_lang_string("screen_3_contdesc"))

contlabel = Gtk::Label.new(extract_lang_string("screen_3") + " " + extract_lang_string("password_explanation"))
userlabel = Gtk::Label.new(extract_lang_string("screen_3_user"))
pwdetlabel = Gtk::Label.new(extract_lang_string("password_explanation"))
contlabel.wrap = true
userlabel.wrap = true
pwdetlabel.wrap = true
contdesc.wrap = true
contlabel.width_request = 550
userlabel.width_request = 550
pwdetlabel.width_request = 550
contdesc.width_request = 550
contlabel.xalign = 0.1
userlabel.xalign = 0.1
pwdetlabel.xalign = 0.1
contdesc.xalign = 0.1

d_table = Gtk::Table.new(2,    2,    false)
dt_options = Gtk::EXPAND|Gtk::FILL
d_pass = Gtk::Entry.new
d_pass.visibility = false
c_pass = Gtk::Entry.new
c_pass.visibility = false
d_table.attach(d_pass,  1,  2,  0,  1, nil, nil, 5, 2)
d_table.attach(c_pass,  1,  2,  1,  2, nil, nil, 5, 2)
p_label = Gtk::Label.new(extract_lang_string("password"))
p_label.xalign = 0
p_label.width_request = 100
c_label = Gtk::Label.new(extract_lang_string("password_confirm"))
c_label.xalign = 0
c_label.width_request = 100
d_table.attach(p_label,  0,  1,  0,  1, dt_options, nil, 5, 2)
d_table.attach(c_label,  0,  1,  1,  2, dt_options, nil, 5, 2)

u_table = Gtk::Table.new(2,    2,    false)
u_pass = Gtk::Entry.new
u_pass.visibility = false
uc_pass = Gtk::Entry.new
uc_pass.visibility = false
u_table.attach(u_pass,  1,  2,  0,  1, nil, nil, 5, 2)
u_table.attach(uc_pass,  1,  2,  1,  2, nil, nil, 5, 2)
u_label = Gtk::Label.new(extract_lang_string("password"))
u_label.xalign = 0
u_label.width_request = 100
uc_label = Gtk::Label.new(extract_lang_string("password_confirm"))
uc_label.xalign = 0
uc_label.width_request = 100
u_table.attach(u_label,  0,  1,  0,  1, dt_options, nil, 5, 2)
u_table.attach(uc_label,  0,  1,  1,  2, dt_options, nil, 5, 2)

contvbox = Gtk::VBox.new(false, 5)
contvbox.pack_start(contdesc, false, true, 5)
contvbox.pack_start(contcheck, false, true, 5)
contvbox.pack_start(partlabel, false, true, 5) 
contvbox.pack_start(partsize, false, true, 5) 
# contvbox.pack_start(partexpl, false, true, 5) 
contvbox.pack_start(contlabel, false, true, 5) 
contvbox.pack_start(d_table, false, true, 5) 
# contvbox.pack_start(userlabel, false, true, 5)
# contvbox.pack_start(u_table, false, true, 5)
# contvbox.pack_start(pwdetlabel, false, true, 5)
unless  get_force_single_part && get_force_nocontainer
	contid = assi.append_page(contvbox)
	assi.set_page_title(contvbox, extract_lang_string("password_title"))
	assi.set_page_type(contvbox, Gtk::Assistant::PAGE_CONTENT)
end
assi.set_page_complete(contvbox, true)
partsize.sensitive = false
d_pass.sensitive = false
c_pass.sensitive = false 
u_pass.sensitive = false
uc_pass.sensitive = false
partsize.sensitive = false
contlabel.sensitive = false
partlabel.sensitive = false
p_label.sensitive = false
c_label.sensitive = false

contcheck.sensitive = false if get_force_nocontainer == true

contcheck.signal_connect("clicked") { |c|
	if contcheck.active? == false
		assi.set_page_complete(contvbox, true)
		d_pass.sensitive = false
		c_pass.sensitive = false 
		u_pass.sensitive = false
		uc_pass.sensitive = false
		partsize.sensitive = false
		contlabel.sensitive = false
		partlabel.sensitive = false
		p_label.sensitive = false
		c_label.sensitive = false
	else
		d_pass.sensitive = true
		c_pass.sensitive = true 
		u_pass.sensitive = true
		uc_pass.sensitive = true
		partsize.sensitive = true
		contlabel.sensitive = true
		partlabel.sensitive = true
		p_label.sensitive = true
		c_label.sensitive = true
		assi.set_page_complete(contvbox, password_compare(d_pass.text, c_pass.text, u_pass.text, uc_pass.text))
	end
}
d_pass.signal_connect("key-release-event") { 
	assi.set_page_complete(contvbox, password_compare(d_pass.text, c_pass.text, u_pass.text, uc_pass.text))
}
c_pass.signal_connect("key-release-event") { 
	assi.set_page_complete(contvbox, password_compare(d_pass.text, c_pass.text, u_pass.text, uc_pass.text))
}
u_pass.signal_connect("key-release-event") { 
	assi.set_page_complete(contvbox, password_compare(d_pass.text, c_pass.text, u_pass.text, uc_pass.text))
}
uc_pass.signal_connect("key-release-event") { 
	assi.set_page_complete(contvbox, password_compare(d_pass.text, c_pass.text, u_pass.text, uc_pass.text))
}

# Letztes Label: Fertig, Neustart

endlabel = Gtk::Label.new(extract_lang_string("confirm_install"))
endcheck = Gtk::CheckButton.new(extract_lang_string("confirm_check"))
endlabel.wrap = true
endlabel.xalign = 0.1
endlabel.width_request = 550
endvbox = Gtk::VBox.new(false, 5)
endvbox.pack_start(endlabel, false, true, 5)
endvbox.pack_start(endcheck, false, true, 5)

endid = assi.append_page(endvbox)
assi.set_page_title(endvbox, extract_lang_string("ready_to_install"))
assi.set_page_type(endvbox, Gtk::Assistant::PAGE_CONFIRM)
assi.set_page_complete(endvbox, false)

assi.set_title  "Install: " + get_brandlong # "Installation COMPUTERBILD Sicher surfen 2009"
assi.border_width = 10
assi.set_size_request(600, 410)

endcheck.signal_connect("clicked") { |c|
	if endcheck.active? == false
		assi.set_page_complete(endvbox, false)	
	else
		assi.set_page_complete(endvbox, true)
	end
}

assi.set_forward_page_func{|curr|
	puts curr
	if curr == 0
		# when switching from first to second screen, read drivelist
		puts "current screen 0, rereading drivelist"
		usbdrives = get_usbdrives_lshw
		puts usbdrives
		usable_drives = create_drivelist(choicebox, usable_drives.size, usbdrives)
		assi.set_page_complete(choice_vbox, usable_drives.size > 0)
		# Before showing, adjust the spinner to the first 
		# element in the list, it should be the smallest
		adjust_size_spinner(partsize, 0, usable_drives)
		1
	else
		curr + 1
	end
}

assi.signal_connect('close')   { |w|
	run_installation(w, usable_drives, choicebox.active, partsize.value, c_pass.text, uc_pass.text, contcheck.active? )
}

assi.signal_connect('cancel')   { |w|
	puts "cleanup and reboot here"
	trigger_reboot
	Gtk.main_quit 
}

assi.signal_connect('delete_event') { 
	puts "cleanup and reboot here"
	trigger_reboot
	Gtk.main_quit 
}

assi.show_all
Gtk.main

