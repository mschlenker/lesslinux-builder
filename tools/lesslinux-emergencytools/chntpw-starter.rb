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
		"no_sam_found" => "Keine SAM-Datei gefunden",
		"no_user_found" => "Keine Nutzer gefunden",
		"please_reread" => "Bitte Nutzer neu einlesen",
		"term_title" => "Passwort zurücksetzen - interaktiv - Bitte nicht schließen",
		"reset_short" => "Passwort erfolgreich zurückgesetzt",
		"reset_long" => "Das Passwort des ausgewählten Nutzers wurde erfolgreich zurückgesetzt.",
		"error_short" => "Fehler beim Zurücksetzen",
		"error_long" => "Beim Versuch, das Passwort zurückzusetzen trat ein Fehler auf!",
		"int_short" => "Aktion ausgeführt" ,
		"int_long" => "Bitte starten Sie Windows nun neu und prüfen Sie, ob die vorgenommenen Einstellungen wirksam sind.",
		"assi_title" => "Zurücksetzen des Windows-Passwortes",
		"assi_desc" => "Dieser Assistent hilft Ihnen beim <b>Zurücksetzen des Passwortes von Windows XP, Vista, 7 oder 8</b>. Nach der Ausführung dieses Programms können Sie sich ohne Passwort an Ihrer Windows-Installation anmelden.",
		"sam_label" => "Wählen Sie die SAM-Datei aus, die Ihre Passwort-Informationen enthält. Sie können die Datei automatisch suchen lassen oder sie direkt wählen. Ihre Windows-Systempartition muss hierfür schreibbar eingebunden sein.",
		"sam_automatic" => "SAM-Datei automatisch suchen",
		"sam_please" => "Bitte Suche starten!",
		"sam_now" => "Jetzt suchen",
		"sam_choose" => "SAM-Datei auswählen",
		"sam_title" => "Auswahl der SAM-Datei",
		"user_desc" => "Wählen Sie das Nutzerkonto, dessen Passwort zurückgesetzt werden soll. In der Liste der Nutzernamen sind Sonderzeichen durch Unterstriche ersetzt. Diese Konten werden dennoch korrekt verarbeitet.",
		"user_button" => "Konten einlesen",
		"user_please" => "Bitte lesen Sie die Nutzerkonten ein!",
		"user_select" => "Auswahl des Nutzerkontos",
		"chntpw_extended" => "Wollen Sie erweiterte Funktionen von \"chntpw\" nutzen? Diese umfassen beispielsweise die Möglichkeit, einem Nutzer Administratorrechte einzuräumen. Die Nutzung erweiterter Funktionen empfehlen wir nur für versierte Anwender!",
		"chntpw_label" => "Erweiterte Funktionen nutzen",
		"confirm" => "Wollen Sie das Zurücksetzen des Passwortes mit den vorgenommenen Einstellungen durchführen?",
		"disclaimer" => "<b>Haftungsausschluß:</b> Ich bin mir bewußt, dass beim Zurücksetzen des Passwortes die Passwortdatei beschädigt werden kann, was zu einem Windows-System führt, das nicht hochfährt oder keine Anmeldung zulässt. Eine Sicherung dieser Datei habe ich daher erstellt.",
		"overview" => "Zusammenfassung",
		"method_standard" => "Standard, nur Zurücksetzen",
		"method_interact" => "Interaktiv, erweiterte Funktionen nutzen",
		"confirm_details" => "<b>SAM-Datei:</b> %SAMFILE%\n\n<b>Nutzerkonto:</b> %USERNAME%\n\n<b>Methode:</b> %METHOD%",
		"program_title" => "Windows-Passwort zurücksetzen"
	},
	"en" => {
		"no_sam_found" => "No SAM file found",
		"no_user_found" => "No users found",
		"please_reread" => "Please re-read the users",
		"term_title" => "Resetting Windows password - please do not close",
		"reset_short" => "Password successfully resetted",
		"reset_long" => "The password of the chosen user was resetted successfully.",
		"error_short" => "Error resetting password",
		"error_long" => "An error occured while resetting the password!",
		"int_short" => "Action finished",
		"int_long" => "Please reboot into Windows to check if the settings made did have an effect.",
		"assi_title" => "Reset your Windows password",
		"assi_desc" => "This program helps <b>resetting the password of of Windows XP, Vista or 7</b>. After running this program you can log on to your Windows account without providing a password.",
		"sam_label" => "Select the SAM file that contains your password information. You can select the SAM file yourself or start an automatic search. The Windows system drive must be mounted writable to enable changes to this file.",
		"sam_automatic" => "Search SAM file automatically",
		"sam_please" => "Please start the search!",
		"sam_now" => "Search now",
		"sam_choose" => "Select SAM file",
		"sam_title" => "Selection of SAM file",
		"user_desc" => "Select the user account for which you want to reset the password. In the list special chars are replaced by underscores. Nevertheless those accounts will be correctly modified.",
		"user_button" => "Refresh user accounts",
		"user_please" => "Please refresh the user accounts!",
		"user_select" => "Select user account",
		"chntpw_extended" => "Do you want to enable extended functions of \"chntpw\"? Those enable you for example to raise anyones privileges to administrator level. We recommend this option for experienced users only!",
		"chntpw_label" => "Enable extended functionality",
		"confirm" => "Do you want to reset your Windows password with the selected settings?",
		"disclaimer" => "<b>Disclaimer:</b> I am aware of the fact that resetting a password can corrupt the SAM file, which leads to an unbootable Windows system. To prevent this I made a backup of the SAM file.",
		"overview" => "Overview",
		"method_standard" => "Standard, reset only",
		"method_interact" => "Interaktive, enable extended functionality",
		"confirm_details" => "<b>SAM file:</b> %SAMFILE%\n\n<b>User account:</b> %USERNAME%\n\n<b>Method:</b> %METHOD%",
		"program_title" => "Reset Windows password"
	},
	"pl" => {
		"no_sam_found" => "Nie odnaleziono pliku SAM",
                "no_user_found" => "Nie odnaleziono żadnych użytkowników",
                "please_reread" => "Odczytaj ponownie listę użytkowników",
                "term_title" => "Usuwanie hasła Windows - nie zamykaj tego okna",
                "reset_short" => "Udało się usunąć hasło",
                "reset_long" => "Hasło wybranego użytkownika zostało usunięte.",
                "error_short" => "Błąd usuwania",
                "error_long" => "Podczas usuwania hasła wystąpił błąd!",
                "int_short" => "Działanie zakończone",
                "int_long" => "Uruchom system Windows aby sprawdzić poprawność działania dokonanych zmian.",
                "assi_title" => "Usuń hasło Windows",
                "assi_desc" => "Ten program umożliwia <b>usunięcie hasła systemowego w Windows XP, Vista i 7</b>. Po zakończeniu działania programu będziesz mógł zalogować się do systemu Windows bez konieczności podania hasła.",
                "sam_label" => "Wybierz plik SAM zawierający informacje o haśle. Możesz wskazać go sam lub uruchomić automatyczne wyszukiwanie. Napęd z systemem Windows musi być zamontowany z możliwością zapisu, inaczej nie da się zmienić zawartości pliku.",
                "sam_automatic" => "Wyszukaj plik SAM automatycznie",
                "sam_please" => "Rozpocznij wyszukiwanie!",
                "sam_now" => "Wyszukaj teraz",
                "sam_choose" => "Wskaż plik SAM",
                "sam_title" => "Wybór pliku SAM",
                "user_desc" => "Wybierz konto użytkownika, którego hasło chcesz usunąć. Znaki specjalne zastąpione są na liście podkreśleniami. Nie wpływa to w żaden sposób na działanie programu.",
                "user_button" => "Odśwież listę kont użytkowników",
                "user_please" => "Odśwież listę kont użytkowników!",
                "user_select" => "Wybierz konto użytkownika",
                "chntpw_extended" => "Czy chcesz wykorzystać zaawansowane funkcje \"chntpw\"? Umożliwiają one m.in. nadanie dowolnemu użytkownikowi przywilejów administratora. Zalecamy ich wykorzystanie tylko doświadczonym użytkownikom!",
                "chntpw_label" => "Włącz funkcje zaawansowane",
                "confirm" => "Czy chcesz wyczyścić hasło Windows wykorzystując wybrane ustawienia?",
                "disclaimer" => "<b>Oświadczenie:</b> Jestem świadom, iż usunięcie hasła może spowodować uszkodzenie pliku SAM, co z kolei może spowodować niemożliwość uruchomienia systemu Windows. Aby temu zapobiec, zrobiłem zapasową kopię pliku SAM.",
                "overview" => "Podsumowanie",
                "method_standard" => "Standardowe, tylko usunięcie",
                "method_interact" => "Interaktywne, włączone funkcje zaawansowane",
                "confirm_details" => "<b>Plik SAM:</b> %SAMFILE%\n\n<b>Konto użytkownika:</b> %USERNAME%\n\n<b>Metoda:</b> %METHOD%",
                "program_title" => "Usuń hasło Windows"
	},
	"es" => {
		"no_sam_found" => "Archivo SAM no encontrado",
                "no_user_found" => "Usuarios no encontrados",
                "please_reread" => "Por favor, vuelva a leer los usuarios",
                "term_title" => "Reestableciendo la contraseña de Windows. Por favor, no cierre",
                "reset_short" => "Contraseña reestablecida correctamente",
                "reset_long" => "La contraseña del usuario elegido fue reestablecida con éxito.",
                "error_short" => "Error al reestablecer la contraseña.",
                "error_long" => "Ocurrió un error mientras se reestablecía la contraseña",
                "int_short" => "Proceso completado",
                "int_long" => "Por favor, reinicie Windows para comprobar que los cambios han tenido efecto.",
                "assi_title" => "Reestablecer la contraseña de Windows.",
                "assi_desc" => "Este programa ayuda <b>a reestablecer la contraseña de Windows XP, Vista o 7</b>. Después de ejecutar este programa, podrá iniciar una sesión en su cuenta de Windows sin usar una contraseña.",
                "sam_label" => "Seleccione el fichero SAM que contiene la información sobre su contraseña. Puede seleccionar el fichero SAM de forma manual o iniciar una búsqueda automática. La unidad de sistema de Windows debe ser configurada como escritura para poder hacer cambios en este archivo.",
                "sam_automatic" => "Búsqueda automática del fichero SAM",
                "sam_please" => "Por favor, inicie la búsqueda ",
                "sam_now" => "Buscar ahora",
                "sam_choose" => "Seleccione el fichero SAM",
                "sam_title" => "Selección del fichero SAM",
                "user_desc" => "Seleccione la cuenta de usuario donde quiere reestablecer la contraseña. Los caracteres especiales en la lista se sustituirán por guiones bajos. Sin embargo, las cuentas serán correctamente modificadas.",
                "user_button" => "Actualizar las cuentas de usuario",
                "user_please" => "Por favor, actualice las cuentas de usuario.",
                "user_select" => "Seleccione una cuenta de usuario",
                "chntpw_extended" => "¿Quiere activar las funciones extendidas de \"chntpw\"? Estas le permitirán, por ejemplo, dotar a cualquier usuario de los permisos a nivel administrador. Recomendamos esta opción sólo para usuarios experimentados",
                "chntpw_label" => "Habilitar la funcionalidad extendida",
                "confirm" => "¿Desea reestablecer la contraseña de Windows con la configuración seleccionada?",
                "disclaimer" => "<b>Exención de responsabilidad:</b>Soy consciente de que al restablecer una contraseña se puede dañar el fichero SAM, lo que impediría el arranque de Windows. Para prevenirlo he realizado una copia de seguridad del fichero.",
                "overview" => "Información general",
                "method_standard" => "Estándar, reestablecer únicamente",
                "method_interact" => "Interactivo, habilitar la funcionalidad extendida",
                "confirm_details" => "<b>Archivo SAM:</b> %SAMFILE%\n\n<b>Cuenta de usuario:</b> %USERNAME%\n\n<b>Método:</b> %METHOD%",
                "program_title" => "Reestablecer la contraseña de Windows"
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

#========================================
# General logic
#========================================

#========================================
# Core logic
#========================================

def find_samfiles
	samfiles = Array.new
	IO.popen("find /media -type f -name SAM") { |io| 
		samfiles.push($_.strip) unless $_ =~ /\/RegBack\// while io.gets
	}
	return samfiles
end

def rebuild_sam_combo(samcombo, samfiles)
	100.downto(0) { |i|
		begin
			samcombo.remove_text(i)
		rescue
		end
	}
	samfiles.each { |j|
		samcombo.append_text(j)
	}
	if samfiles.size < 1
		samcombo.append_text(extract_lang_string("no_sam_found"))
		samcombo.sensitive = false
	else
		samcombo.sensitive = true
	end
	samcombo.active = 0
end

def read_userlist(samfile)
	samusers = Array.new
	IO.popen("chntpw -l '" + samfile + "'") { |io|
		accstart = false
		while io.gets
			toks = $_.split("|")
			if accstart == true
				$stderr.puts "Hex ID:" + toks[1].to_s.strip
				$stderr.puts "Username: " + toks[2].to_s.strip.gsub(/[^[:print:]]/, '_')
				samusers.push( [ toks[1].to_s.strip, toks[2].to_s.strip.gsub(/[^[:print:]]/, '_') ] )
			end
			accstart = true if $_ =~ / ^|\sRID/
		end
	}
	return samusers
end

def update_user_combo(usercombo, samusers)
	100.downto(0) { |i|
		begin
			usercombo.remove_text(i)
		rescue
		end
	}
	samusers.each { |u|
		usercombo.append_text(u[1])
	}
	if samusers.size > 0
		usercombo.sensitive = true
		usercombo.active = 0
		return true
	else
		usercombo.append_text(extract_lang_string("no_user_found"))
		usercombo.active = 0
		usercombo.sensitive = false
		return false
	end
end

def reset_sam_users(usercombo)
	100.downto(0) { |i|
		begin
			usercombo.remove_text(i)
		rescue
		end
	}
	usercombo.append_text(extract_lang_string("please_reread"))
	usercombo.active = 0
	usercombo.sensitive = false
end

def apply_settings(samfile, hexaccount, interactive, assi)
	if interactive == true
		exstring = "Terminal --geometry=80x25 --hide-toolbars --hide-menubar --disable-server -T \"" + extract_lang_string("term_title") + "\" -x chntpw -u 0x" + hexaccount + " '" + samfile + "'"
	else
		exstring = "printf \"1\\ny\\n\" | chntpw -u 0x" + hexaccount + " '" + samfile + "'"
		# exstring = "printf \"1\\ny\\n\" | chntpw -u 0x03ff '" + samfile + "'"
	end
	$stderr.puts exstring
	system(exstring)
	retval = $?.exitstatus
	$stderr.puts retval.to_s
	if retval == 2 && interactive == false
		dialog = Gtk::Dialog.new(extract_lang_string("reset_short"),assi,Gtk::Dialog::MODAL,
			[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
		)
		dialog.has_separator = false
		label = Gtk::Label.new(extract_lang_string("reset_long"))
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
	elsif interactive == false
		dialog = Gtk::Dialog.new(extract_lang_string("error_short"),assi,Gtk::Dialog::MODAL,
			[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
		)
		dialog.has_separator = false
		label = Gtk::Label.new(extract_lang_string("error_long"))
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
	else
		dialog = Gtk::Dialog.new(extract_lang_string("int_short"),assi,Gtk::Dialog::MODAL,
			[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
		)
		dialog.has_separator = false
		label = Gtk::Label.new(extract_lang_string("int_long"))
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
	end
end

#========================================
# Globally used vars
#========================================

#LANGUAGE = ENV['LANGUAGE'][0..1]

#@xbranding = File.new( "/etc/lesslinux/branding/branding.xml" )
#@branding = REXML::Document.new  @xbranding

assi = Gtk::Assistant.new
# assi.deletable = false
samfiles = Array.new
samusers = Array.new

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
# Second window - search SAM file
#========================================

searchlabel = Gtk::Label.new
searchlabel.set_markup(extract_lang_string("sam_label"))
searchlabel.wrap = true
searchlabel.width_request = 550
searchlabel.xalign = 0.1
searchbox = Gtk::VBox.new(false, 5)
searchradio = Gtk::RadioButton.new(extract_lang_string("sam_automatic"))
searchcombo = Gtk::ComboBox.new
searchcombo.append_text(extract_lang_string("sam_please"))
searchcombo.active = 0
searchcombo.sensitive = false
searchbutton = Gtk::Button.new(extract_lang_string("sam_now"))
searchhbox = Gtk::HBox.new(false, 5)
searchhbox.pack_start(searchcombo, true, true, 5)
searchhbox.pack_start(searchbutton, false, true, 5)
searchman = Gtk::RadioButton.new(searchradio, extract_lang_string("sam_choose"))
searchchooser  = Gtk::FileChooserButton.new(extract_lang_string("sam_choose"), Gtk::FileChooser::ACTION_OPEN)
searchchooser.current_folder = "/media"
searchchooser.use_preview_label = false
searchchooser.sensitive = false

searchbox.pack_start(searchlabel, false, true, 5)
searchbox.pack_start(searchradio, false, true, 5)
searchbox.pack_start(searchhbox, false, true, 5)
searchbox.pack_start(searchman, false, true, 5)
searchbox.pack_start(searchchooser, false, true, 5)

searchpage = assi.append_page(searchbox)
assi.set_page_title(searchbox, extract_lang_string("sam_title"))
assi.set_page_type(searchbox, Gtk::Assistant::PAGE_CONTENT)
assi.set_page_complete(searchbox, false)

#========================================
# Third window - choose user to edit 
#========================================

userlabel = Gtk::Label.new
userlabel.set_markup(extract_lang_string("user_desc"))
userlabel.wrap = true
userlabel.width_request = 550
userlabel.xalign = 0.1
usercombo = Gtk::ComboBox.new
userbutton = Gtk::Button.new(extract_lang_string("user_button"))
usercombo.append_text(extract_lang_string("user_please"))
usercombo.active = 0
usercombo.sensitive = false
userhbox = Gtk::HBox.new(false, 5)
userhbox.pack_start(usercombo, true, true, 5)
userhbox.pack_start(userbutton, false, true, 5)

methlabel = Gtk::Label.new
methlabel.set_markup(extract_lang_string("chntpw_extended"))
methlabel.wrap = true
methlabel.width_request = 550
methlabel.xalign = 0.1
methcheck = Gtk::CheckButton.new(extract_lang_string("chntpw_label"))

userbox = Gtk::VBox.new(false, 5)
userbox.pack_start(userlabel, false, true, 5)
userbox.pack_start(userhbox, false, true, 5)
userbox.pack_start(methlabel, false, true, 5)
userbox.pack_start(methcheck, false, true, 5)

userpage = assi.append_page(userbox)
assi.set_page_title(userbox, extract_lang_string("user_select"))
assi.set_page_type(userbox, Gtk::Assistant::PAGE_CONTENT)
assi.set_page_complete(userbox, false)

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

#========================================
# Common settings and callbacks
#========================================

searchradio.signal_connect('clicked') {
	searchbutton.sensitive = true
	searchchooser.sensitive = false
	searchcombo.sensitive = true if samfiles.size > 0
	reset_sam_users(usercombo)
	assi.set_page_complete(userbox, false)
	lastcheck.active = false
	if samfiles.size < 1
		assi.set_page_complete(searchbox, false)
	else
		assi.set_page_complete(searchbox, true)
	end
}

searchman.signal_connect('clicked') {
	searchbutton.sensitive = false
	searchchooser.sensitive = true
	searchcombo.sensitive = false
	reset_sam_users(usercombo)
	assi.set_page_complete(userbox, false)
	lastcheck.active = false
	assi.set_page_complete(lastbox, false)
	if searchchooser.filename.nil?
		assi.set_page_complete(searchbox, false)
	else
		assi.set_page_complete(searchbox, true)
	end
}

searchbutton.signal_connect('clicked') {
	samfiles = find_samfiles
	rebuild_sam_combo(searchcombo, samfiles)
}

searchchooser.signal_connect('selection_changed') {
	reset_sam_users(usercombo)
	lastcheck.active = false
	assi.set_page_complete(lastbox, false)
	assi.set_page_complete(userbox, false)
	assi.set_page_complete(searchbox, true) unless searchchooser.filename.nil?
}

searchcombo.signal_connect('changed') {
	reset_sam_users(usercombo)
	lastcheck.active = false
	assi.set_page_complete(lastbox, false)
	assi.set_page_complete(userbox, false)
	assi.set_page_complete(searchbox, true) if samfiles.size > 0
}

userbutton.signal_connect('clicked') {
	if searchradio.active?
		samfile = samfiles[searchcombo.active]
	else
		samfile = searchchooser.filename
	end
	samusers = read_userlist(samfile)
	assi.set_page_complete(userbox, update_user_combo(usercombo, samusers))
}

lastcheck.signal_connect('clicked') { |b|
	if b.active? 
		assi.set_page_complete(lastbox, true)
	else
		assi.set_page_complete(lastbox, false)
	end
}

assi.set_forward_page_func{|curr|
	samfile = nil
	if searchradio.active?
		samfile = samfiles[searchcombo.active]
	else
		samfile = searchchooser.filename
	end
	unless methcheck.active?
		method = extract_lang_string("method_standard")
	else
		method = extract_lang_string("method_interactive")
	end
	username = "unknown"
	username =  samusers[usercombo.active][1].to_s if samusers.size > 0
	ovlabel.set_markup(extract_lang_string("confirm_details").gsub("%SAMFILE%",samfile.to_s).
		gsub("%USERNAME%", username).gsub("%METHOD%", method) )
	curr += 1
}

assi.set_title  extract_lang_string("program_title")
assi.border_width = 10
assi.set_size_request(600, 410)
assi.signal_connect('destroy') { Gtk.main_quit }
assi.signal_connect('cancel')  { assi.destroy }
assi.signal_connect('close')   { |w|
	if searchradio.active?
		samfile = samfiles[searchcombo.active]
	else
		samfile = searchchooser.filename
	end
	hex_account =  samusers[usercombo.active][0]
	apply_settings(samfile, hex_account, methcheck.active?, assi)
	w.destroy
}

assi.show_all
Gtk.main