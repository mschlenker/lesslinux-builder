#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
require "rexml/document"
require "digest/sha1"
require "vte"

LANGUAGE = ENV['LANGUAGE'][0..1]
LOCSTRINGS = {
	"de" => {
		"bank2011" => {
			"reinit_explanation" => "Sie haben bisher noch keinen Datentresor eingerichtet. Legen Sie daher zunächst ein Passwort fest, mit dem Sie bei künftigen Starts den Tresor öffnen können. Das Passwort erlaubt Ihnen auch das Speichern von Bankeinstellungen, Internet-Einstellungen und Bankdokumenten.",
			"password_details" => "Das Passwort muss mindestens acht Zeichen lang sein und mindestens einen Klein-, einen Großbuchstaben sowie eine Zahl enthalten.",
			"pw_minlength" => "8",
			"password_title" => "COMPUTERBILD Homebanking plus"
		},
		"password_explanation" => "Hier müssen Sie ein Passwort für den Zugriff auf Laufwerke vergeben. Falls Sie kein Passwort vergeben, startet %BRANDLONG% ohne Zugriff auf Laufwerke und Einstellungen.",
		"password" => "Passwort:",
		"password_confirm" => "Bestatigung:",
		"password_title" => "Passwörter",
		"password_details" => "Das Passwort muss wenigstens zehn Zeichen lang sein und mindestens einen Klein-, einen Großbuchstaben sowie eine Zahl enthalten.",
		"container_password" => "Geben Sie das Passwort für Ihren Datentresor ein. Falls Sie das Eingabefeld leer lassen, startet %BRANDLONG% ohne Zugriff auf Ihre persönlichen Einstellungen.",
		"container_title" => "Zugriff auf Datentresor",
		"container_wrong_pass" => "Fehler: Falsches Passwort oder beschädigter Datentresor! Der Start wird ohne Datentresor fortgesetzt.",
		"container_fs_damaged" => "Zugriff auf Datentresor nicht möglich: Korrektes Passwort, aber beschädigtes Dateisystem!",
		"driver_xorg" => "Xorg (automatische Auswahl)", 
		"driver_xvesa" => "VESA (langsam, funktioniert immer)",
		"monitor_auto" => "automatisch erkennen", 
		"monitor_tft" => "Flachbildschirm/TFT (60Hz)",
		"monitor_crt" => "Röhrenmonitor (75Hz)",
		"x_driver" => "Treiber:",
		"x_monitor" => "Monitor:",
		"x_resolution" => "Auflösung:",
		"x_auto" => "bereits automatisch eingestellt",
		"x_title" => "Monitor und Grafikkarte",
		"reinit_title" => "Datentresor einrichten",
		"reinit_explanation" => "Der Datentresor wurde noch nicht initialisiert oder soll neu initialisiert werden. Bitte geben Sie das neue Passwort für den Datentresor zweimal ein.",
		"pw_minlength" => "10",
		"fail_quest" =>  "Fehler: Falsches Passwort oder beschädigter Datentresor! Wie wollen Sie weiter vorgehen?",
		"fail_retry" => "Zurück zur Passworteingabe",
		"fail_without" => "Ohne Datentresor starten",
		"fail_reinit" => "Datentresor neu initialisieren",
		"apply" => "Anwenden",
		"x_short" => "Wählen Sie Grafiktreiber, Monitor und Auflösung",
		"x_test" => "Test"
	},
	"en" => {
		"bank2011" => {
			"reinit_explanation" => "You did not yet configure the encrypted container. Set a password that is used to open the container. The password also allows saving bank settings, internet settings and documents.",
			"password_details" => "The password must use at least eight characters and contain small and large characters and a number.",
			"pw_minlength" => "8",
			"password_title" => "COMPUTERBILD Homebanking plus"
		},
		"password_explanation" => "Here you can set a password that is used to access drives. If you do not set a password, access to drives will be denied.",
		"password" => "Password:",
		"password_confirm" => "Confirmation:",
		"password_title" => "Passwords",
		"password_details" => "The password length is ten characters minumum. It must contain numbers, uppercase and lowercase letters.",
		"container_password" => "Enter the password for the encrypted container. If you leave this field empty %BRANDLONG% will be started without access to your encrypted files.",
		"container_title" => "Access encrypted container",
		"container_wrong_pass" => "Error: Wrong password or damaged container! The start will be continued without access to your encrypted files.",
		"container_fs_damaged" => "Access to encrypted container not possible: correct password, but damaged filesystem!",
		"driver_xorg" => "Xorg (automatically detect)", 
		"driver_xvesa" => "VESA (slower, compatible to all cards)",
		"monitor_auto" => "automatically detect", 
		"monitor_tft" => "Flatscreen (60Hz)",
		"monitor_crt" => "CRT (75Hz)",
		"x_driver" => "Driver:",
		"x_monitor" => "Monitor:",
		"x_resolution" => "Resolution:",
		"x_auto" => "already automatically set",
		"x_title" => "Monitor and graphic card",
		"reinit_title" => "Setup crypt container",
		"reinit_explanation" => "Either the crypt container is not yet initialized or a re-initialization was requested. Please provide a new password for the container.",
		"pw_minlength" => "10",
		"fail_quest" =>  "Error: Wrong password or damaged container! What do you want to do?",
		"fail_retry" => "Retry password entry",
		"fail_without" => "Start without encrypted container",
		"fail_reinit" => "Re-initialize encrypted container",
		"apply" => "Apply",
		"x_short" => "Choose graphics driver, monitor and resolution",
		"x_test" => "Test"
	},
	"es" => {
		"bank2011" => {
			"reinit_explanation" => "You did not yet configure the encrypted container. Set a password that is used to open the container. The password also allows saving bank settings, internet settings and documents.",
			"password_details" => "The password must use at least eight characters and contain small and large characters and a number.",
			"pw_minlength" => "8",
			"password_title" => "COMPUTERBILD Homebanking plus"
		},
                "password_explanation" => "Aquí tienes que poner la contraseña que uses para acceder a los discos. Si no lo haces, el acceso a los mismos te será denegado.",
                "password" => "Contraseña:",
                "password_confirm" => "Confirma contraseña:",
                "password_title" => "Contraseñas",
                "password_details" => "La extensión mínima de la contraseña es de diez caracteres. Debe incluir números, mayúsculas y minúsculas.",
                "container_password" => "Introduce la contraseña para cifrar el contenido. Si dejas vacío este campo, %BRANDLONG% se iniciará sin acceso a tus ficheros cifrados.",
                "container_title" => "Acceso a contenido cifrado",
                "container_wrong_pass" => "Error: Contraseña equivocada o archivo contenedor dañado. El inicio continuará sin acceso a tus ficheros cifrados.",
                "container_fs_damaged" => "El acceso al contenido cifrado no ha sido posible: la contraseña es correcta, pero el sistema de archivos está dañado.",
                "driver_xorg" => "Xorg (detección automática)",
                "driver_xvesa" => "VESA (lento, compatible con todas las tarjetas)",
                "monitor_auto" => "detección automática",
                "monitor_tft" => "Pantalla plana (60Hz)",
                "monitor_crt" => "CRT (75Hz)",
                "x_driver" => "Controlador:",
                "x_monitor" => "Monitor:",
                "x_resolution" => "Resolución:",
                "x_auto" => "ya definido automáticamente",
                "x_title" => "Monitor y tarjeta gráfica",
		"pw_minlength" => "10" ,
		"fail_retry" => "Retry password entry",
		"fail_without" => "Start without encrypted container",
		"x_short" => "Choose graphics driver, monitor and resolution",
		"x_test" => "Test",
		"fail_quest" =>  "Error: Wrong password or damaged container! What do you want to do?",
		"apply" => "Apply",
		"reinit_title" => "Setup crypt container",
		"reinit_explanation" => "Either the crypt container is not yet initialized or a re-initialization was requested. Please provide a new password for the container.",
		"fail_reinit" => "Re-initialize encrypted container"
        },
	"ru" => {
		"bank2011" => {
			"reinit_explanation" => "You did not yet configure the encrypted container. Set a password that is used to open the container. The password also allows saving bank settings, internet settings and documents.",
			"password_details" => "The password must use at least eight characters and contain small and large characters and a number.",
			"pw_minlength" => "8",
			"password_title" => "COMPUTERBILD Homebanking plus"
		},
                "password_explanation" => "Здесь нужно ввести пароль, который будет использоваться для доступа к устройствам. Если вы не введете пароль, доступ к устройствам будет закрыт.",
                "password" => "Пароль:",
                "password_confirm" => "Подтверждение пароля:",
                "password_title" => "Пароли",
                "password_details" => "Длина пароля должна быть не менее 10 символов. Пароль должен содержать цифры, заглавные и строчные буквы.",
                "container_password" => "Введите пароль для зашифрованного контейнера. Если вы оставите поле пустым, программа %BRANDLONG% будет запущена без доступа к зашифрованным файлам.",
                "container_title" => "Доступ к зашифрованному контейнеру",
                "container_wrong_pass" => "Ошибка: неправильный пароль или поврежденный контейнер! Запуск будет продолжен без предоставления доступа к зашифрованным файлам.",
                "container_fs_damaged" => "Доступ к зашифрованному контейнеру невозможен: пароль правильный, но повреждена файловая система!",
                "driver_xorg" => "Xorg (определяется автоматически)", 
                "driver_xvesa" => "VESA (медленный, совместимый со всеми картами)",
                "monitor_auto" => "определяется автоматически", 
                "monitor_tft" => "Монитор (60 Гц)",
                "monitor_crt" => "CRT (75 Гц)",
                "x_driver" => "Драйвер:",
                "x_monitor" => "Монитор:",
                "x_resolution" => "Разрешение:",
                "x_auto" => "определяется автоматически",
                "x_title" => "Монитор и видеокарта",
		"pw_minlength" => "10" ,
		"fail_retry" => "Retry password entry",
		"fail_without" => "Start without encrypted container",
		"x_short" => "Choose graphics driver, monitor and resolution",
		"x_test" => "Test",
		"fail_quest" =>  "Error: Wrong password or damaged container! What do you want to do?",
		"apply" => "Apply",
		"reinit_title" => "Setup crypt container",
		"reinit_explanation" => "Either the crypt container is not yet initialized or a re-initialization was requested. Please provide a new password for the container.",
		"fail_reinit" => "Re-initialize encrypted container"
        },
	"pl" => {
		"bank2011" => {
			"reinit_explanation" => "Ciagle jeszcze nie skonfigurowano zaszyfrowanego kontenera. Wpisz hasło, które jest używane do otwierania kontenera. To hasło pozwala również na dostęp do banku zapisanych ustawień, opcji internetowych oraz dokumentów.", 
			"password_details" => "Hasło musi zawierać co najmniej osiem znaków, duże i małe litery oraz cyfry. ", 
			"pw_minlength" => "8", 
			"password_title" => "Komputer Świat Bezpieczny Bank Online"
		},
                "password_explanation" => "W tym miejscu możesz ustawić hasło wymagane do uzyskania dostępu do dysków. Jeśli nie ustawisz hasła, dyski nie będą dostępne.",
                "password" => "Hasło:",
                "password_confirm" => "Powtórz hasło:",
                "password_title" => "Hasła",
                "password_details" => "Minimalna długość hasła to 10 znaków. Musi ono zawierać cyfry oraz małe i wielkie litery.",
                "container_password" => "Podaj hasło dla zaszyfrowanego pojemnika. Jeśli nie podasz hasła, %BRANDLONG% zostanie uruchomiony bez dostępu do plików zaszyfrowanych.",
                "container_title" => "Dostęp do pojemnika zaszyfrowanego",
                "container_wrong_pass" => "Błąd: Niewłaściwe hasło lub uszkodzony pojemnik! Rozruch będzie kontynuowany bez dostępu do plików zaszyfrowanych.",
                "container_fs_damaged" => "Dostęp do pojemnika zaszyfrowanego niemożliwy: poprawne hasło, ale uszkodzony system plików!",
                "driver_xorg" => "Xorg (wykryj automatycznie)",
                "driver_xvesa" => "VESA (powolny, ale działa z każdą kartą graficzną)",
                "monitor_auto" => "wykryj automatycznie",
                "monitor_tft" => "Płaski (LCD) (60Hz)",
                "monitor_crt" => "Kineskopowy (CRT) (75Hz)",
                "x_driver" => "Sterownik:",
                "x_monitor" => "Monitor:",
                "x_resolution" => "Rozdzielczość:",
                "x_auto" => "już skonfigurowane automatycznie",
                "x_title" => "Monitor i karta graficzna",
		"pw_minlength" => "10",
		"fail_quest" =>  "Błąd: Niewłaściwe hasło lub uszkodzony kontener! Co chcesz teraz zrobić?",
                "fail_retry" => "Ponów wpisanie hasła",
                "fail_without" => "Uruchom bez dostępu do szyfrowanego kontenera",
                "fail_reinit" => "Spróbuj ponownie otworzyć zaszyfrowany kontener",
		"apply" => "Zastosuj",
		"x_short" => "Wybierz sterownik grafiki, monitor i rozdzielczosc",
		"x_test" => "Testuj",
		"reinit_title" => "Ustawienia szyfrowanego wolumenu",
		"reinit_explanation" => "Albo kontener programu szyfrującego nie został jeszcze zainicjowany,  albo wymagana była ponowna inicjalizacja. Proszę podać nowe hasło do kontenera."
        }
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

def extract_lang_string(string_id)
	lang = "en"
	lang = LANGUAGE unless LANGUAGE.nil?
	message_string = "message not found: " + string_id
	begin
		message_string = LOCSTRINGS['en'][string_id] unless LOCSTRINGS['en'][string_id].nil?
	rescue
	end
	begin
		message_string = LOCSTRINGS[lang][string_id] unless LOCSTRINGS[lang][string_id].nil?
	rescue
	end
	begin
		message_string = LOCSTRINGS[lang][get_brandshort][string_id] unless LOCSTRINGS[lang][get_brandshort][string_id].nil?
	rescue
	end
	return message_string.gsub('%BRANDLONG%', get_brandlong)
end

def run_with_progress(command)
	ctoks = command.split
	dialog = Gtk::Dialog.new(
		"Be patient...",
		$mainwindow,
		Gtk::Dialog::MODAL
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_OK
	dialog.has_separator = false
	pgbar = Gtk::ProgressBar.new
	pgbar.width_request = 400
	pgbar.height_request = 24
	dialog.vbox.add(pgbar)
	vte = Vte::Terminal.new
	cmd_running = true
	dialog.show_all
	vte.signal_connect("child-exited") { cmd_running = false } 
	vte.fork_command(ctoks[0], ctoks)
	while cmd_running == true
		pgbar.pulse
		sleep 0.2
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
	end
	dialog.destroy
end

def request_container_reinit(hexdigest)
	return true if hexdigest.to_s == "2bccbd2f38f15c13eb7d5a89fd9d85f595e23bc3"
	bltoks = Array.new
	reinit = false
	File.open("/proc/cmdline").each { |line|
		bltoks = line.split unless line.strip == ""
	}
	# first check if container reinit is requested by boot parameter
	bltoks.each { |t|
		key_val = t.split("=")
		# puts key_val[0]
		# puts key_val[1].to_s
		if key_val[0] == "reinitcont" && key_val[1].to_s.to_i > 0
			puts "RETURNING true"
			return true
		end
	}
	puts "RETURNING false"
	return false
end

# FIXME: Put these functions to a separate file

def password_compare(user_pw, user_conf, root_pw, root_conf)
	if root_pw.size == 0 && root_conf.size == 0
		return user_pw == user_conf && check_pw_policy(user_pw)
	elsif user_pw.size == 0 && user_conf.size == 0
		return root_pw == root_conf && check_pw_policy(root_pw)
	else
		return user_pw == user_conf && root_pw == root_conf && check_pw_policy(user_pw) && check_pw_policy(root_pw)
	end
	return false
end

def check_pw_policy(password) 
	# pw_minlength = 
	unless LANGUAGE == "pl" || LANGUAGE == "ru"
		return password.size > extract_lang_string("pw_minlength").to_i - 1 &&  password =~ /[A-Z]/ && password =~ /[a-z]/ && password =~ /[0-9]/
	else
		return password.size > extract_lang_string("pw_minlength").to_i - 1 &&  password =~ /[0-9]/
	end
end

def create_pw_hash(user, pw)
	puts("== Replace password hash ==")
	# puts pw
	return false if pw.length < 10
	system(	"echo -n '" + pw.gsub("'", "\\\\" + '\'') + "' | openssl passwd -1 -stdin > /etc/lesslinux/" + user + ".hash") 
	system( "/etc/rc.d/0040-roothash.sh start")
end

# try to find the partition with home.llc

def find_home_container

	# Search partitions by UUID
	cryptpart = ""
	IO.popen("cat /proc/cmdline") { |i|
		while i.gets
			ltoks = $_.split
			ltoks.each { |p|
				if p =~ /^crypt=/ && p != "crypt=all"
					uuid = p.split('=')[1]
					cryptpart = ` blkid -U #{uuid} `.strip
				end
			}
		end
	}
	# Search partitions by label 
	cryptpart = ` blkid -L LessLinuxCrypt `.strip if cryptpart == "" 
	unless cryptpart.to_s == ""
		sha1sum = ` dd if=#{cryptpart} bs=4M count=1 | sha1sum `.split[0].strip 
		fstype=` blkid -o udev -s TYPE #{cryptpart} `.split("=")[1].strip 
		sha1sum = "2bccbd2f38f15c13eb7d5a89fd9d85f595e23bc3" if fstype =~ /^ext/ 
		return cryptpart, sha1sum 
	end
	
	container_paths = [ "binary/" + get_brandshort + ".llc", get_brandshort + ".llc", "binary/home.llc", "home.llc" ]
	# default_container = "/lesslinux/cdrom/home.llc"
	container_paths.each { |c|
		if File.exist?("/lesslinux/cdrom/" + c)
			system("mount -o remount,rw /lesslinux/cdrom")
			teststr = String.new
			open("/lesslinux/cdrom/" + c) { |f| teststr = f.read(4194304) }
			digest = Digest::SHA1.hexdigest(teststr)
			return "/lesslinux/cdrom/" + c, digest
		end
	}
	# also search in the directory where the ISO is found
	IO.popen("losetup -a") { |l|
		while l.gets
			ltoks = $_.split
			if ltoks[2].strip =~ /iso\)/ 
				d = File.dirname(ltoks[2].strip.gsub('(', '').gsub(')', ''))
				container_paths.each { |c|
					if File.exist?(d + "/" + c)
						teststr = String.new
						open(d + "/" + c) { |f| teststr = f.read(4194304) }
						digest = Digest::SHA1.hexdigest(teststr)
						return d + "/" + c, digest
					end
				}
			end
		end
	}
	fatvols = Array.new
	extvols = Array.new
	ntfsvols = Array.new
	lcount = 0
	
	# Scan partition identified by uuid=UUID... first
	
	IO.popen("cat /proc/cmdline") { |i|
		while i.gets
			ltoks = $_.split
			ltoks.each { |p|
				if p =~ /^uuid=/ && p != "uuid=all"
					uuid = p.split('=')[1]
					dev = ` blkid -U #{uuid} ` 
					system("mount -o ro " + dev + " /lesslinux/cryptpart")
					container_paths.each { |c|
						if File.exist?("/lesslinux/cryptpart/" + c)
							system("mount -o remount,rw /lesslinux/cryptpart")
							teststr = String.new
							open("/lesslinux/cryptpart/" + c) { |f| teststr = f.read(4194304) }
							digest = Digest::SHA1.hexdigest(teststr)
							return "/lesslinux/cryptpart/" + c, digest
						end
						system("umount /lesslinux/cryptpart")
					}
				end
			}
		end
	}	
	
	IO.popen("cat /proc/partitions") { |i|
		while i.gets
			ltoks = $_.split
			unless ltoks[3].nil? || ltoks[3].to_s =~/loop/ || ltoks[3].to_s =~/name/ || ltoks[3].to_s == ""
				fs = nil
				IO.popen("blkid -o udev /dev/" + ltoks[3].to_s.strip) { |j|
					while j.gets
						btoks = $_.split('=')
						if btoks[0] == "ID_FS_TYPE"
							if btoks[1].strip =~ /ext/i || btoks[1].strip =~ /btrfs/i 
								extvols.push("/dev/" + ltoks[3].to_s)
							elsif btoks[1].strip =~ /fat/i
								fatvols.push("/dev/" + ltoks[3].to_s)
							elsif btoks[1].strip =~ /ntfs/i
								ntfsvols.push("/dev/" + ltoks[3].to_s)
							end
						end
					end
				}
			end
		end
	}
	system("mkdir /lesslinux/cryptpart")
	container_paths.each { |c|
		(extvols + fatvols).each { |i|
			system("mount -o ro " + i + " /lesslinux/cryptpart")
			if File.exist?("/lesslinux/cryptpart/" + c)
				system("mount -o remount,rw /lesslinux/cryptpart")
				teststr = String.new
				open("/lesslinux/cryptpart/" + c) { |f| teststr = f.read(4194304) }
				digest = Digest::SHA1.hexdigest(teststr)
				return "/lesslinux/cryptpart/" + c, digest
			end
			system("umount /lesslinux/cryptpart")
		}
		ntfsvols.each { |i|
			system("mount -t ntfs-3g -o ro " + i + " /lesslinux/cryptpart")
			if File.exist?("/lesslinux/cryptpart/" + c)
				system("mount -o remount,rw /lesslinux/cryptpart")
				teststr = String.new
				open("/lesslinux/cryptpart/" + c) { |f| teststr = f.read(4194304) }
				digest = Digest::SHA1.hexdigest(teststr)
				return "/lesslinux/cryptpart/" + c, digest
			end
			system("umount /lesslinux/cryptpart")
		}
	}
	return nil, nil
end

# only for CB  banking!
def find_old_container
	container_path = "binary/bank2010.llc" 
	mnt_points = [ "/lesslinux/cdrom", "/lesslinux/cryptpart", "/lesslinux/convertold" ] 
	mnt_points.each { |d|
		if File.exist?(d + "/" + container_path)
			system("mount -o remount,rw " + d)
			puts "=== Found old container at: " + d
			return d
		end
	}
	fatvols = Array.new
	extvols = Array.new
	lcount = 0
	# Find all partitions identified by lshw
	IO.popen("lshw-static -quiet -short -class volume") { |i|
		while i.gets
			cols = $_.split(/\s{2,}/)
			if lcount > 1 && cols[3].to_s =~ /FAT/i
				fatvols.push(cols[1])
			elsif lcount > 1 && cols[3].to_s =~ /EXT/i
				extvols.push(cols[1])
			end
			lcount += 1
		end
	}
	system("mkdir -p /lesslinux/convertold")
	(extvols + fatvols).each { |i|
		system("mount -o ro " + i + " /lesslinux/convertold")
		if File.exist?("/lesslinux/convertold/" + container_path)
			system("mount -o remount,rw /lesslinux/convertold")
			puts "=== Found old container at: /lesslinux/convertold"
			return "/lesslinux/convertold"
		end
		system("umount /lesslinux/convertold")
	}
	return nil
end

def find_fat_container
	container_paths = [ get_brandshort + ".vol", "home.vol" ]
	# default_container = "/lesslinux/cdrom/home.llc"
	mount_points = [ "/lesslinux/cdrom/", "/lesslinux/cryptpart/" ]
	mount_points.each { |m|
		container_paths.each { |c|
			if File.exist?(m + c)
				system("mount -o remount,rw " + m)
				return m + c
			end
		}
	}
	# FIXME: Search on other devices as well! 
	return nil
end

def save_xorg_settings( driver_combo, resolutions, res_combo, monitor_modes, mon_combo )
	outfile = File.new("/var/run/lesslinux/xorg_vars", "w")
	# outfile = File.new("/tmp/xorg_vars", "w")
	if driver_combo.active == 0
		# outfile.write("driver=xorg\n")
		outfile.write("xorgconf=/etc/X11/Xorg.conf.xorg\n")
	else
		# outfile.write("driver=xvesa\n")
		outfile.write("xorgconf=/etc/X11/Xorg.conf.vesa\n")
	end
	res = resolutions[res_combo.active]
	# outfile.write("vesapref=" + res + "x24\n")
	outfile.write("xorgscreen=Screen_" + monitor_modes[mon_combo.active] + "_" + res + "\n")
	outfile.close
end

def mount_crypt_container(container, pw)
	puts("== Mount crypt container ==")
	system("/sbin/modprobe -v dm-crypt")
	system("/sbin/modprobe -v sha256")
	system("mdev -s")
	free_loop = "/dev/loop9999" # nil
	IO.popen("losetup -f") { |i| 
		while i.gets
			free_loop = $_.to_s.strip
		end
	}
	contisdev = false
	contisdev = true if File.stat(container).blockdev? 
	system("losetup " + free_loop.to_s + " " + container.to_s ) unless contisdev == true
	free_loop = container if contisdev == true
	unless system("echo '" + pw.gsub("'", "\\\\" + '\'') + "' | cryptsetup luksOpen -q " + free_loop + " " + free_loop.gsub("/dev/", ""))
		system( "cryptsetup luksClose " + free_loop.gsub("/dev/", "") )
		system( "losetup -d " + free_loop ) unless contisdev == true
		system( "umount /lesslinux/cryptpart" ) unless contisdev == true
		return false, extract_lang_string("container_wrong_pass")
	end
	unless system("mount -t ext4 -o nodev,nosuid /dev/mapper/" + free_loop.gsub("/dev/", "") + " /home")
		# try to repair fs, preen should be safe enough
		system("/sbin/fsck.ext4 -p /dev/mapper/" + free_loop.gsub("/dev/", "") ) 
		unless system("mount -o nodev,nosuid /dev/mapper/" + free_loop.gsub("/dev/", "") + " /home")
			system("cryptsetup luksClose " + free_loop.gsub("/dev/", "") )
			system("losetup -d " + free_loop) unless contisdev == true
			system("umount /lesslinux/cryptpart") unless contisdev == true
			return false, extract_lang_string("container_fs_damaged")
		end
	end
	system("rsync -avHP /home/.overlay/ /")
	system("ln -s /dev/mapper/" +  free_loop.gsub("/dev/", "") + " /dev/mapper/lesslinux_crypt") 
	system("ln -s /dev/mapper/lesslinux_crypt #{container}.child") if contisdev == true 
	return true, "Access to encrypted container successful!"
end

def mount_fat_container(container, pw)
	unless File.exists?(container)
		return false, "Container file non-existent!"
	end
	puts("== Mount crypt container ==")
	system("/sbin/modprobe -v dm-crypt")
	system("/sbin/modprobe -v sha256")
	system("mdev -s")
	free_loop = "/dev/loop9999" # nil
	IO.popen("losetup -f") { |i| 
		while i.gets
			free_loop = $_.to_s.strip
		end
	}
	cleaned_name = File.split(container)[1].gsub(".", "_")
	system("losetup " + free_loop.to_s + " " + container.to_s )
	system("echo '" + pw.gsub("'", "\\\\" + '\'') + "' | cryptsetup luksOpen -q " + free_loop + " " + cleaned_name)
	system("mkdir -p -m 0755 /media/" + cleaned_name )
	system("mount -o noexec,nodev,nosuid,gid=1000,uid=1000,iocharset=utf8 -t vfat /dev/mapper/" + cleaned_name + " /media/" + cleaned_name)
	return true, "FAT32 container successfully mounted"
end

def reinit_container(container, pw, convert=false)
	puts("== Replace password hash ==")
	# puts pw
	system(	"echo -n '" + pw.gsub("'", "\\\\" + '\'') + "' | openssl passwd -1 -stdin > /etc/lesslinux/surfer.hash") 
	system( "/etc/rc.d/0040-roothash.sh start")
	puts("== Reinitializing crypt container ==")
	system("/sbin/modprobe -v dm-crypt")
	system("/sbin/modprobe -v sha256")
	system("mdev -s")
	free_loop = "/dev/loop9999" # nil
	IO.popen("losetup -f") { |i| 
		while i.gets
			free_loop = $_.to_s.strip
		end
	}
	contisdev = false
	contisdev = true if File.stat(container).blockdev? 
	system("losetup " + free_loop.to_s + " " + container.to_s ) unless contisdev == true
	free_loop = container if contisdev == true
	uuid=''
	if contisdev == true
		uuid = ` blkid -o udev -s UUID #{container} | head -n1 `.split("=")[1].strip 
	end
	puts("=== Writing random data to old container")
	system("dd if=/dev/urandom bs=1M count=4 of=" + free_loop.to_s)
	if contisdev == true
		system("echo '" + pw.gsub("'", "\\\\" + '\'') + "' | cryptsetup luksFormat --uuid=#{uuid} -c aes-cbc-essiv:sha256 -s 256 -q " + free_loop ) 
	else
		system("echo '" + pw.gsub("'", "\\\\" + '\'') + "' | cryptsetup luksFormat -c aes-cbc-essiv:sha256 -s 256 -q " + free_loop ) 
	end
	# open the container
	system("echo '" + pw.gsub("'", "\\\\" + '\'') + "' | cryptsetup luksOpen -q " + free_loop + " " + free_loop.gsub("/dev/", "") )
	system("mdev -s")
	run_with_progress("mkfs.ext4 /dev/mapper/" + free_loop.gsub("/dev/", "") )
	system("mkdir  /lesslinux/tmp_home")
	system("mount -t ext4 /dev/mapper/" + free_loop.gsub("/dev/", "") +  " /lesslinux/tmp_home")
	system("rsync -avHP /home/ /lesslinux/tmp_home/")
	system("mkdir -m 0755 -p /lesslinux/tmp_home/.overlay/etc")
	system("rsync -avHP /etc/shadow /lesslinux/tmp_home/.overlay/etc")
	system("rsync -avHP /etc/passwd /lesslinux/tmp_home/.overlay/etc")
	oldcont = find_old_container
	if !oldcont.nil? && convert == true
		next_loop = "/dev/loop9999"
		IO.popen("losetup -f") { |i| 
			while i.gets
				next_loop = $_.to_s.strip
			end
		}
		savefiles =  [ 	"etc/wicd/wired-settings.conf", 
				"etc/wicd/wireless-settings.conf",
				"etc/wicd/manager-settings.conf", 
				"etc/lesslinux/banking/allowedservers.xml" ]
		system("mkdir -p /lesslinux/tmp_oldhome")
		system("losetup " + next_loop.to_s + " " + oldcont + "/binary/bank2010.llc" )
		system("echo '" + pw.gsub("'", "\\\\" + '\'') + "' | cryptsetup luksOpen -q " + next_loop.to_s + " lesslinux_oldhome" )
		system("mdev -s")
		system("mount /dev/mapper/lesslinux_oldhome /lesslinux/tmp_oldhome")
		if system("cat /proc/mounts | grep -q /lesslinux/tmp_oldhome") 
			savefiles.each { |f|
				system("/bin/tar -C /lesslinux/tmp_oldhome/.overlay -cvf - " + f + " | /bin/tar -C /lesslinux/tmp_home/.overlay -xf - ") 
				puts("/bin/tar -C /lesslinux/tmp_oldhome/.overlay -cvf - " + f + " | /bin/tar -C /lesslinux/tmp_home/.overlay -xf - ") 
			}
		end
		system("umount /lesslinux/tmp_oldhome")
		system("cryptsetup luksClose /dev/mapper/lesslinux_oldhome")
		system("losetup -d " + next_loop)
		system("umount /lesslinux/convertold")
	end
	system("umount /lesslinux/tmp_home/")
	system("cryptsetup luksClose /dev/mapper/" + free_loop.gsub("/dev/", "") )
	system("losetup -d " + free_loop) unless contisdev == true
	# system("umount /lesslinux/install_target")
end

def reinit_fat_container(container, pw, convert=false)
	unless File.exists?(container)
		return false, "Container file non-existent!"
	end
	teststr = String.new
	open(container) { |f| teststr = f.read(4194304) }
	digest = Digest::SHA1.hexdigest(teststr)
	unless digest.to_s == "2bccbd2f38f15c13eb7d5a89fd9d85f595e23bc3"
		return false, "Container not empty" 
	end
	cleaned_name = File.split(container)[1].gsub(".", "_")
	puts("== Reinitializing crypt container ==")
	system("/sbin/modprobe -v dm-crypt")
	system("/sbin/modprobe -v sha256")
	system("mdev -s")
	free_loop = "/dev/loop9999" # nil
	IO.popen("losetup -f") { |i| 
		while i.gets
			free_loop = $_.to_s.strip
		end
	}
	system("losetup " + free_loop.to_s + " " + container.to_s )
	puts("=== Writing random data to old container")
	system("dd if=/dev/urandom bs=1M count=4 of=" + free_loop.to_s)
	system("echo '" + pw.gsub("'", "\\\\" + '\'') + "' | cryptsetup luksFormat -c aes-cbc-essiv:sha256 -s 256 -q " + free_loop ) 
	# open the container
	system("echo '" + pw.gsub("'", "\\\\" + '\'') + "' | cryptsetup luksOpen -q " + free_loop + " " + cleaned_name)
	system("mdev -s")
	system("mkfs.msdos -F32 /dev/mapper/" + cleaned_name )
	oldcont = find_old_container
	if convert == true && !oldcont.nil?
		system("mkdir -p /lesslinux/tmp_oldvol /lesslinux/tmp_newvol")
		system("mount -t vfat /dev/mapper/" + cleaned_name + " /lesslinux/tmp_newvol") 
		next_loop = "/dev/loop9999"
		IO.popen("losetup -f") { |i| 
			while i.gets
				next_loop = $_.to_s.strip
			end
		}
		system("losetup " + next_loop.to_s + " " + oldcont + "/bank2010.vol" )
		system("echo '" + pw.gsub("'", "\\\\" + '\'') + "' | cryptsetup luksOpen -q " + next_loop.to_s + " lesslinux_oldvol" )
		system("mdev -s")
		system("mount /dev/mapper/lesslinux_oldvol /lesslinux/tmp_oldvol")
		if system("cat /proc/mounts | grep -q /lesslinux/tmp_oldvol") && system("cat /proc/mounts | grep -q /lesslinux/tmp_newvol") 
			system("/bin/tar -C /lesslinux/tmp_oldvol -cvf - . | /bin/tar -C /lesslinux/tmp_newvol -xf - ") 
			puts("/bin/tar -C /lesslinux/tmp_oldvol -cvf - . | /bin/tar -C /lesslinux/tmp_newvol -xf - ") 
		end
		system("umount /lesslinux/tmp_oldvol")
		system("cryptsetup luksClose /dev/mapper/lesslinux_oldvol")
		system("losetup -d " + next_loop)
		system("umount /lesslinux/convertold")
		system("umount /lesslinux/tmp_newvol")
	end
	system("cryptsetup luksClose /dev/mapper/" + cleaned_name )
	system("losetup -d " + free_loop)
	# system("umount /lesslinux/install_target")
	return true, "Container successfully (re-) initialized!"
end

def fixbootconf
	# system("sed -i 's/reinitcont=1//g' /lesslinux/cdrom/syslinux.cfg")
end

def show_error_dialog(message)
	dialog = Gtk::MessageDialog.new($main_application_window, 
			Gtk::Dialog::MODAL,
			Gtk::MessageDialog::ERROR,
			Gtk::MessageDialog::BUTTONS_CLOSE,
			message)
	dialog.run
	dialog.destroy
end

def show_try_again(message)
	dialog = Gtk::Dialog.new(
		"Container access failed",
		$main_application_window,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ],
		[ Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL ]
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_OK
	lab = Gtk::Label.new(extract_lang_string("fail_quest"))
	lab.wrap = true
	rad = Gtk::RadioButton.new(extract_lang_string("fail_retry"))
	rad2 = Gtk::RadioButton.new(rad, extract_lang_string("fail_without"))
	rad3 = Gtk::RadioButton.new(rad, extract_lang_string("fail_reinit"))
	label1 = Gtk::Label.new(extract_lang_string("password"))
	label2 = Gtk::Label.new(extract_lang_string("password_confirm"))
	pwstr = Gtk::Entry.new
	pwconstr = Gtk::Entry.new
	pwstr.sensitive = false
	pwconstr.sensitive = false
	pwstr.visibility = false
	pwconstr.visibility = false
	rad3.signal_connect('toggled') {
		if rad3.active? == true
			pwstr.sensitive = true
			pwconstr.sensitive = true
			dialog.set_response_sensitive(Gtk::Dialog::RESPONSE_OK, false)
		else
			pwstr.sensitive = false
			pwconstr.sensitive = false
			dialog.set_response_sensitive(Gtk::Dialog::RESPONSE_OK, true)
		end
	}
	pwstr.signal_connect("key-release-event") { 
		dialog.set_response_sensitive(Gtk::Dialog::RESPONSE_OK, password_compare(pwstr.text, pwconstr.text, "", "") && check_pw_policy(pwstr.text))
	}
	pwconstr.signal_connect("key-release-event") { 
		dialog.set_response_sensitive(Gtk::Dialog::RESPONSE_OK, password_compare(pwstr.text, pwconstr.text, "", "") && check_pw_policy(pwstr.text))
	}
	layouttab = Gtk::Table.new(2, 2, false)
	layouttab.attach_defaults(label1, 0, 1, 0, 1)
	layouttab.attach_defaults(label2, 0, 1, 1, 2)
	layouttab.attach_defaults(pwstr,   1, 2, 0, 1)
	layouttab.attach_defaults(pwconstr,   1, 2, 1, 2)
	layouttab.row_spacings = 3
	layouttab.column_spacings = 3
	layouttab.border_width = 10
	dialog.vbox.add(lab)
	dialog.vbox.add(rad)
	dialog.vbox.add(rad2)
	dialog.vbox.add(rad3)
	dialog.vbox.add(layouttab)
	dialog.show_all
	close_assistent = false
	dialog.run do |response|
		if response == Gtk::Dialog::RESPONSE_OK
			if rad.active?
				# Retry password entry
				close_assistent = false
			elsif rad2.active?
				# Start without container
				close_assistent = true
			elsif rad3.active?
				crypt_container, hexdigest = find_home_container
				create_pw_hash("surfer", pwstr.text) unless pwstr.text.size < 1
				reinit_container(crypt_container, pwstr.text)
				success, message = mount_crypt_container(crypt_container, pwstr.text)
				# find the fat container if it exists
				fatcont = find_fat_container
				unless fatcont.nil?
					reinit_fat_container(fatcont, pwstr.text) 
					mount_fat_container(fatcont, pwstr.text)
				end
				close_assistent = true
			end
		end
	end
	dialog.destroy
	return close_assistent
end

def trigger_reboot
	system("/static/sbin/reboot")
end

# build the GUI
# first step is finding the encrypted container
# and checking if sudo is set lax

crypt_container, hexdigest = find_home_container
laxsudo = system("check_lax_sudo")

# Immediately exit gracefully if
#  - no container is found
#  - sudo uses lax settings
#  - monitor is already configured
exit 0 if File.exists?("/var/run/lesslinux/xconfgui_skip_monitor") && laxsudo == true && crypt_container.nil?

# If no cryptcontainer is found and lax sudo privileges are set
# just one page is needed - so no assistent is necessary, use a
# plain window instead:

if crypt_container.nil? && laxsudo
	assi = Gtk::Window.new(Gtk::Window::TOPLEVEL)
	assi.deletable = false
else
	assi = Gtk::Assistant.new
	assi.deletable = false
end
assi.window_position = Gtk::Window::POS_CENTER_ALWAYS

# first window, create vbox for entry of user and root password

# contlabel = Gtk::Label.new(extract_lang_string("password_explanation"))
# not used!
userlabel = Gtk::Label.new("Ein Administratorpasswort wird nur in seltenen Fällen, beispielsweise für Support-Aufgaben benötigt.")
# not used!
pwdetlabel = Gtk::Label.new(extract_lang_string("password_details"))

userlabel.wrap = true
pwdetlabel.wrap = true

userlabel.width_request = 550
pwdetlabel.width_request = 550
userlabel.xalign = 0.1
pwdetlabel.xalign = 0.1

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
encvbox = Gtk::VBox.new(false, 5)

if crypt_container.nil? && laxsudo == false
	contid = assi.append_page(contvbox)
	assi.set_page_title(contvbox, extract_lang_string("password_title"))
	assi.set_page_type(contvbox, Gtk::Assistant::PAGE_CONTENT)
	assi.set_page_complete(contvbox, true) # false)
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
	contlabel = Gtk::Label.new(extract_lang_string("password_explanation"))
	contlabel.wrap = true
	contlabel.width_request = 550
	contlabel.xalign = 0.1
elsif !crypt_container.nil? && request_container_reinit(hexdigest) == true
	contid = assi.append_page(contvbox)
	assi.set_page_title(contvbox, extract_lang_string("reinit_title"))
	assi.set_page_type(contvbox, Gtk::Assistant::PAGE_CONTENT)
	assi.set_page_complete(contvbox, true) # false)
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
	contlabel = Gtk::Label.new(extract_lang_string("reinit_explanation"))
	contlabel.wrap = true
	contlabel.width_request = 550
	contlabel.xalign = 0.1
elsif !crypt_container.nil?
	contid = assi.append_page(encvbox)
	assi.set_page_title(encvbox, extract_lang_string("password_title") )
	assi.set_page_type(encvbox, Gtk::Assistant::PAGE_CONTENT)
	assi.set_page_complete(encvbox, true) # false)
end

# Nothing to append to the assistent if laxsudo == true and crypt_container.nil? !

contvbox.pack_start(contlabel, false, true, 5) 
contvbox.pack_start(d_table, false, true, 5) 
# contvbox.pack_start(userlabel, false, true, 5)
# contvbox.pack_start(u_table, false, true, 5)
contvbox.pack_start(pwdetlabel, false, true, 5)

## migration add ons
old_container = nil
mig_checkbox = Gtk::CheckButton.new("Einstellungen von Bank 2010 übernehmen (neues Passwort muss dem alten entsprechen)?")
if !old_container.nil? && request_container_reinit(hexdigest) == true
	old_container = find_old_container
	unless old_container.nil?
		mig_checkbox.width_request = 550
		mig_checkbox.xalign = 0.1
		mig_checkbox.active = true
		contvbox.pack_start(mig_checkbox, false, true, 5)
	end
end

# first window alternatively create vbox for entry of container password

enclabel = Gtk::Label.new(extract_lang_string("container_password"))
enclabel.wrap = true
enclabel.width_request = 550
enclabel.xalign = 0.1
enc_table = Gtk::Table.new(1,    2,    false)
enct_options = Gtk::EXPAND|Gtk::FILL
enc_pass = Gtk::Entry.new
enc_pass.visibility = false
enc_table.attach(enc_pass,  1,  2,  0,  1, nil, nil, 5, 2)
enc_ent_label = Gtk::Label.new(extract_lang_string("password"))
enc_ent_label.xalign = 0
enc_ent_label.width_request = 100
enc_table.attach(enc_ent_label,  0,  1,  0,  1, enct_options, nil, 5, 2)

encvbox.pack_start(enclabel, false, true, 5)
encvbox.pack_start(enc_table, false, true, 5)

# Second and last page: create monitor selection

drivers = [ extract_lang_string("driver_xorg"), extract_lang_string("driver_xvesa") ]
resolutions = [ 
		"1920x1200",  
		"1920x1080", 
		"1680x1050", 
		"1600x1200", 
		"1440x900", 
		"1400x1050", 
		"1366x768", 
		"1280x1024", 
		"1280x800", 
		"1024x768", 
		"1024x600", 
		"800x600", 
		"800x480", 
		"640x480" ]
monitors = [ extract_lang_string("monitor_auto"), extract_lang_string("monitor_tft"), extract_lang_string("monitor_crt") ]
monitor_modes = [ "AUTO", "TFT", "CRT" ]
monitor_layout_table = Gtk::Table.new(5, 2, false)
driver_combo = Gtk::ComboBox.new
drivers.each { |i| driver_combo.append_text(i) }
res_combo = Gtk::ComboBox.new
resolutions.each { |i| res_combo.append_text(i) }
res_combo.active = 9
mon_combo = Gtk::ComboBox.new
monitors.each { |i| mon_combo.append_text(i) }
mon_combo.active = 0
button_box = Gtk::HBox.new(true, 5)
test_button = Gtk::Button.new(extract_lang_string("x_test"))
test_button.signal_connect("clicked") { |w|
	outfile = File.new("/var/run/lesslinux/xorg_vars.test", "w")
	# outfile = File.new("/tmp/xorg_vars", "w")
	if driver_combo.active == 0
		# outfile.write("driver=xorg\n")
		outfile.write("xorgconf=/etc/X11/Xorg.conf.xorg\n")
	else
		outfile.write("xorgconf=/etc/X11/Xorg.conf.vesa\n")
	end
	res = resolutions[res_combo.active]
	# outfile.write("vesapref=" + res + "\n")
	outfile.write("xorgscreen=Screen_" + monitor_modes[mon_combo.active] + "_" + res + "\n")
	outfile.close
	system("/bin/bash /usr/local/xconfgui/trigger_configtest")
}

# save_button = Gtk::Button.new("Speichern")
button_box.pack_start(test_button, true, true, 5)
# button_box.pack_start(save_button, true, true, 5)
# monitor_layout_table.attach(head, 0, 2, 0, 1 , Gtk::EXPAND, Gtk::SHRINK, 5, 15)
monitor_layout_table.attach(driver_combo,  1,  2,  1,  2, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 5, 2)
monitor_layout_table.attach(Gtk::Label.new(extract_lang_string("x_driver")), 0,  1,  1,  2, Gtk::SHRINK, Gtk::SHRINK, 5, 2)
monitor_layout_table.attach(res_combo,  1,  2,  2,  3, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 5, 2)
monitor_layout_table.attach(Gtk::Label.new(extract_lang_string("x_resolution")), 0,  1,  2,  3, Gtk::SHRINK, Gtk::SHRINK, 5, 2)
monitor_layout_table.attach(mon_combo,  1,  2,  3,  4, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 5, 2)
monitor_layout_table.attach(Gtk::Label.new(extract_lang_string("x_monitor")), 0,  1,  3,  4, Gtk::SHRINK, Gtk::SHRINK, 5, 2)
monitor_layout_table.attach(button_box, 0,  2,  4,  5, Gtk::FILL|Gtk::EXPAND, Gtk::SHRINK, 5, 2)

if File.exists?("/var/run/lesslinux/xconfgui_xorg")
	driver_combo.active = 0
else
	driver_combo.active = 1
	# test_button.sensitive = false
end
if File.exists?("/var/run/lesslinux/xconfgui_skip_monitor")
	driver_combo.active = 0
	driver_combo.sensitive = false
	(resolutions.size - 1).downto(0) { |i|
		res_combo.remove_text(i)
	}
	res_combo.append_text(extract_lang_string("x_auto"))
	res_combo.active = 0
	res_combo.sensitive = false
	mon_combo.sensitive = false
	test_button.sensitive = false
end


if laxsudo == false || !crypt_container.nil?
	endid = assi.append_page(monitor_layout_table)
	assi.set_page_title(monitor_layout_table, extract_lang_string("x_title"))
	assi.set_page_type(monitor_layout_table, Gtk::Assistant::PAGE_CONFIRM)
	assi.set_page_complete(monitor_layout_table, true)
	assi.signal_connect('close')   { |w|
		close_assi = true
		# save settings
		# user password
		create_pw_hash("surfer", d_pass.text) unless d_pass.text.size < 1
		# root password
		create_pw_hash("root", u_pass.text) unless u_pass.text.size < 1
		# save Xorg settings
		save_xorg_settings( driver_combo, resolutions, res_combo, monitor_modes, mon_combo ) unless 
			File.exists?("/var/run/lesslinux/xconfgui_skip_monitor")
		# mount the crypt container
		if d_pass.text.size > 0 && request_container_reinit(hexdigest) == true
			puts("=== Yeah, reinit container!")
			reinit_container(crypt_container, d_pass.text, mig_checkbox.active?)
			success, message = mount_crypt_container(crypt_container, d_pass.text)
			# find the fat container if it exists
			fatcont = find_fat_container
			# FIXME: this won't work for now if the partition with the container is not already mounted
			unless fatcont.nil?
				reinit_fat_container(fatcont, d_pass.text, mig_checkbox.active?) 
				mount_fat_container(fatcont, d_pass.text)
			end
			fixbootconf if success == true
			show_error_dialog(message) if success == false
		elsif enc_pass.text.size > 0
			success, message = mount_crypt_container(crypt_container, enc_pass.text) 
			# find the fat container if it exists
			fatcont = find_fat_container
			# FIXME: this will just work if the container is either on the system partition or on the 
			# partition containing the home container
			mount_fat_container(fatcont, enc_pass.text) unless fatcont.nil?
			# show_error_dialog(message) if success == false
			if success == false
				close_assi = show_try_again(message)
			else
				close_assi = true
			end
		else
			system("umount /lesslinux/cryptpart")
			close_assi = true
		end
		Gtk.main_quit if close_assi == true
	}
	assi.signal_connect('cancel')   { |w|
		puts "cleanup and reboot here?"
		trigger_reboot
		Gtk.main_quit
	}
	windims = [ 600, 410 ]
else
	apply_button = Gtk::Button.new(extract_lang_string("apply"))
	button_box.pack_start(apply_button, true, true, 5)
	lvbox = Gtk::VBox.new(false, 5) 
	mlabel = Gtk::Label.new(extract_lang_string("x_short"))
	#mlabel.width_request = 450
	#mlabel.xalign = 0.1
	fat_font = Pango::FontDescription.new("Sans Bold")
	mlabel.modify_font(fat_font)
	mlabel.wrap = true
	lvbox.pack_start(mlabel, false, true, 5)
	lvbox.pack_start(monitor_layout_table)
	assi.add(lvbox)
	apply_button.signal_connect("clicked") { |w|
		save_xorg_settings( driver_combo, resolutions, res_combo, monitor_modes, mon_combo ) unless
			File.exists?("/var/run/lesslinux/xconfgui_skip_monitor")
		Gtk.main_quit 
	}
	windims = [ 450, 180 ]
end

# common settings

assi.set_title  "Startup: " + get_brandlong
assi.border_width = 10
assi.set_size_request(windims[0], windims[1])

assi.signal_connect('delete_event') { 
	puts "cleanup and reboot here?"
	trigger_reboot
	Gtk.main_quit 
}

assi.show_all
Gtk.main

