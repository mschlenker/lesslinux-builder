#!/usr/bin/ruby
# encoding: utf-8

require "rexml/document"
require 'glib2'
require 'gtk2'

LANGUAGE = ENV['LANGUAGE'][0..1]

#@xbranding = File.new( "/etc/lesslinux/branding/branding.xml" )
#@branding = REXML::Document.new  @xbranding

LOCSTRINGS = {
	"de" => {
		"prog_name" => "Netzlaufwerke",
		"pw_access" => "Diese Aktion erfordert Ihr Passwort für den Laufwerkszugriff:",
		"pw_short" => "Passwort:",
		"pw_title" => "Passwort",
		"pw_remote" => "Geben Sie hier Nutzernamen und Passwort für den entfernten Server ein:",
		"pw_user" => "Nutzer:",
		"mount_button" => "%SHARE% einbinden",
		"mount_unmount" => "%SHARE% lösen",
		"mount_writable" => "schreibbar?",
		"mount_content" => "Inhalt anzeigen",
		"mount_mo_failed" => "Der Laufwerkszugriff ist fehlgeschlagen!",
		"mount_um_failed" => "Das Lösen der Laufwerkseinbindung ist fehlgeschlagen!",
		"mount_no_shares" => "Auf diesem Server wurden keine Freigaben gefunden. Möglicherweise haben Sie mit einem anderen Passwort oder Nutzer mehr Glück.",
		"mount_no_servers" => "Es wurden keine Rechner gefunden, die Windows-Freigaben bereitstellen. Möglicherweise verhindern Firewall- oder Netzwerkeinstellungen einen Zugriff oder die Freigaben sind nur mit Nutzernamen und Passwort sichtbar. Schließen Sie dieses Fenster und starten Sie das Programm nach Überprüfung der Einstellungen erneut.",
		"browse_label" => "Soll bereits bei der Suche nach Freigaben Nutzername und Passwort verwendet werden? Einige Computer zeigen vorhandene Freigaben nur angemeldeten Nutzern an."
	},
	"en" => {
		"prog_name" => "Network shares",
		"pw_access" => "Your password is needed to mount network shares:",
		"pw_short" => "Password:",
		"pw_title" => "Password",
		"pw_remote" => "Please enter username and password for the remote server:",
		"pw_user" => "User:",
		"mount_button" => "Mount %SHARE%",
		"mount_unmount" => "Unmount %SHARE%",
		"mount_writable" => "writable?",
		"mount_content" => "Show content",
		"mount_mo_failed" => "Failed mounting the share!",
		"mount_um_failed" => "Failed unmounting the share!",
		"mount_no_shares" => "No shares were found on this server. You might try browsing with a different password or username.",
		"mount_no_servers" => "No servers were found that provide windows shares. Maybe firewall or network settings prevent access or some shares are only visible when browsing with username and password. Close this window and start the program again with different credentials.",
		"browse_label" => "Do you want to provide a username and password for browsing? Some servers show shares only to users that are signed on."
	},
	"es" => {
		"prog_name" => "Compartir redes",
                "pw_access" => "Es necesario introducir su contraseña para configurar recursos compartidos en red:",
                "pw_short" => "Contraseña:",
                "pw_title" => "Contraseña",
                "pw_remote" => "Por favor, escriba el nombre de usuario y la contraseña del servidor remoto:",
                "pw_user" => "Usuario:",
                "mount_button" => "Montar %SHARE%",
                "mount_unmount" => "Desmontar %SHARE%",
                "mount_writable" => "¿De escritura?",
                "mount_content" => "Mostrar contenido",
                "mount_mo_failed" => "Error al compartir recursos",
                "mount_um_failed" => "Error al desconfigurar compartir recursos",
                "mount_no_shares" => "No se han encontrado recursos compartidos en este servidor. Inténtelo con una contraseña o nombre de usuarios diferentes.",
                "mount_no_servers" => "No se han encontrado servirdores que proporcionen recursos compartidos de Windows. Quizá un cortafuegos o la configuración de la red para prevenir el acceso o compartir algunos recursos son sólo visibles cuando se navega con un usuario y contraseña. Cierre esta ventana e inicie el programa de nuevo con otro usuario.",
                "browse_label" => "¿Desea proveer un nombre de usuario y una contraseña para navegar? Algunos servidores podrán compartir recursos con los usuarios que se registren en ellos."
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

def get_smb_servers(browse_with_pass, default_user, default_pass)
	workgroups = Hash.new
	hostdescs = Hash.new
	smbshares = Hash.new
	tree_command = "smbtree -N"
	tree_command = "smbtree -U '" + default_user.to_s + "%" + default_pass.to_s + "'" if browse_with_pass == true
	IO.popen(tree_command) { |io|
		wgroup = nil
		hostname = nil
		while io.gets
			unless $_.strip =~ /\\\\/
				wgroup = $_.strip
			end
			if $_ =~ /^\t\\\\/
				namedesc = $_.strip.split(/\t+/)
				hostname = namedesc[0].strip.gsub('\\', '')
				begin
					hostdescs[hostname] = namedesc[1].strip
				rescue
					hostdescs[hostname] = ""
				end
				workgroups[hostname] = wgroup
				smbshares[hostname] = Array.new
			elsif $_ =~ /^\t\t\\\\/
				sharedesc = $_.strip.split(/\t+/)
				begin
					sharedet = sharedesc[1].strip
				rescue
					sharedet = ""
				end
				smbshares[hostname].push( [ sharedesc[0].strip.gsub(hostname, '').gsub('\\', ''), sharedet ] ) unless
					sharedesc[0].strip.gsub(hostname, '').gsub('\\', '') == 'IPC$' ||
					sharedesc[0].strip.gsub(hostname, '').gsub('\\', '') == 'C$' ||
					sharedesc[0].strip.gsub(hostname, '').gsub('\\', '') == 'ADMIN$'
			end
		end
	}
	return smbshares, hostdescs, workgroups
end

def show_mounted_shares
	mount_shares = Array.new
	mount_points = Array.new
	mount_opts = Array.new
	IO.popen("cat /proc/mounts") { |io|
		while io.gets
			toks = $_.split
			if toks[2] =~ /cifs/ || toks[2] =~ /smbfs/
				mount_shares.push(toks[0].strip.gsub("\\040", " "))
				mount_points.push(toks[1].strip.gsub("\\040", " "))
				mount_opts = toks[3].strip.split(',')
			end
		end
	}
	return mount_shares, mount_points, mount_opts
end

def query_name(hostname)
	lastline = nil
	nmb_ip = nil
	IO.popen("nmblookup " + hostname) { |io|
		lastline = $_.strip while io.gets
	}
	nmb_ip = lastline.split[0].strip unless lastline =~ /^name_query failed/
	return nmb_ip
end

def error_dialog(parent, message)
	dialog = Gtk::MessageDialog.new(parent, 
			Gtk::Dialog::MODAL,
			Gtk::MessageDialog::ERROR,
			Gtk::MessageDialog::BUTTONS_CLOSE,
			message)
	dialog.run
	dialog.destroy
end

def pw_dialog(parent, default_user, default_pass)
	laxsudo = system("check_lax_sudo")
	success = false
	password = nil
	smb_user = nil
	smb_password = nil
	dialog = Gtk::Dialog.new(
		extract_lang_string("pw_title"),
		parent,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL ],
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	# dialog.set_size_request(300, -1)
	dialog.default_response = Gtk::Dialog::RESPONSE_OK
	question  = Gtk::Label.new(extract_lang_string("pw_access"))
	question.wrap = true
	question.width_request = 300
	entry_label = Gtk::Label.new(extract_lang_string("pw_short"))
	entry_label.width_request = 75
	pass = Gtk::Entry.new
	pass.visibility = false
	qbox = Gtk::VBox.new(false, 5)
	qbox.pack_start(question, false, true, 5)
	hbox = Gtk::HBox.new(false, 5)
	hbox.pack_start(entry_label, false, true, 5)
	hbox.pack_start(pass, true, true, 5)
	if laxsudo == false
		dialog.vbox.add(qbox)
		dialog.vbox.add(hbox)
	end
	# New: ask for username and password on the share
	slabel = Gtk::Label.new(extract_lang_string("pw_remote"))
	slabel.wrap = true
	slabel.width_request = 300
	sbox = Gtk::VBox.new(false, 5)
	sbox.pack_start(slabel, false, true, 5)
	dialog.vbox.add(sbox)
	ulabel = Gtk::Label.new(extract_lang_string("pw_user"))
	ulabel.width_request = 75
	uentry = Gtk::Entry.new
	uentry.text = default_user.to_s
	smblabel = Gtk::Label.new(extract_lang_string("pw_short"))
	smblabel.width_request = 75
	smbpass = Gtk::Entry.new
	smbpass.visibility = false
	smbpass.text = default_pass.to_s
	smbbox = Gtk::HBox.new(false, 5)
	smbbox.pack_start(smblabel, false, true, 5)
	smbbox.pack_start(smbpass, true, true, 5)
	ubox = Gtk::HBox.new(false, 5)
	ubox.pack_start(ulabel, false, true, 5)
	ubox.pack_start(uentry, true, true, 5)
	dialog.vbox.add(ubox)
	dialog.vbox.add(smbbox)
	smbpass.signal_connect('activate') {
		dialog.response(Gtk::Dialog::RESPONSE_OK)
	}
	dialog.show_all
	dialog.run do |response|
		 if response == Gtk::Dialog::RESPONSE_OK
			password = pass.text
			smb_user = uentry.text 
			smb_password = smbpass.text
			success = true
		end
		# return success, pass.text
		dialog.destroy
	end
	return success, password, smb_user, smb_password
end

def build_panel(smbshares, hostdescs, workgroups, window, default_user, default_pass)
	laxsudo = system("check_lax_sudo")
	outer_vbox = Gtk::VBox.new(false, 1)
	fat_font = Pango::FontDescription.new("Sans Bold")
	mount_shares, mount_points, mount_opts = show_mounted_shares
	smbshares.each { |k, v|
		# First the label
		serverdesc = k + " (Workgroup: " + workgroups[k] + ")"
		l = Gtk::Label.new(serverdesc)
		l.modify_font(fat_font)
		l.wrap = true
		# get the hosts IP
		ip = query_name(k)
		# $stderr.puts "Host: " + k + " IP: " + ip
		
		# Now the shares provided by this server:
		outer_vbox.pack_start(l, false, false, 5)
		sharecount = 0
		v.each { |s|
			sharecount += 1
			writeable = Gtk::CheckButton.new(extract_lang_string("mount_writable"))
			mount_string = s[0]
			mount_string = mount_string + " (" + s[1] + ")" unless s[1].strip == ""
			mount_button = Gtk::Button.new(extract_lang_string("mount_button").gsub("%SHARE%", mount_string))
			mount_button.width_request = 260
			mount_button.height_request = 32
			show_button = Gtk::Button.new(extract_lang_string("mount_content"))
			show_button.width_request = 120
			show_button.height_request = 32
			show_button.sensitive = false
			# check if this share is mounted - path is like
			if mount_shares.include?( ("//" + ip + "/" + s[0]) )
				mount_button.label = extract_lang_string("mount_unmount").gsub("%SHARE%", mount_string)
				show_button.sensitive = true
				writeable.sensitive = false
				writeable.active = true if mount_opts.include?("rw")
			end
			mount_button.signal_connect( "clicked" ) {|w|
				if mount_shares.include?( ("//" + ip + "/" + s[0]) )
					umount_success = system("sudo umount '" + mount_points[mount_shares.index("//" + ip + "/" + s[0])] + "'")
					# system("umount '" + mount_points[mount_shares.index("//" + ip + "/" + s[0])] + "'")
					if umount_success # == true
						mount_button.label = extract_lang_string("mount_button").gsub("%SHARE%", mount_string)
						writeable.sensitive = true
						show_button.sensitive = false
					else
						error_dialog(window, extract_lang_string("mount_um_failed"))
					end
				else
					# Query passwords here!
					pw_success, password, smb_user, smb_password = pw_dialog(window, default_user, default_pass)
					if pw_success == true
						rwopt = "ro"
						rwopt = "rw" if writeable.active?
						if laxsudo == true
							mkdir = "sudo mkdir -p '/media/cifs/" + k.downcase + "/" + s[0] + "'"
							mount = "sudo mount.cifs '//" + ip + "/" + s[0] + "'" + 
								" '/media/cifs/" + k.downcase + 
								"/" + s[0] + "' -o " + rwopt + ",user='" + smb_user + 
								"',password='" + smb_password + 
								"',uid=1000,gid=1000,iocharset=utf8"
						else
							mkdir = "echo '" + password + "' | sudo -S mkdir -p '/media/cifs/" + k.downcase + "/" + s[0] + "'"
							mount = "echo '" + password + "' | sudo -S mount.cifs '//" + ip + "/" + s[0] + "'" + 
								" '/media/cifs/" + k.downcase + 
								"/" + s[0] + "' -o " + rwopt + ",user='" + smb_user + 
								"',password='" + smb_password + 
								"',uid=1000,gid=1000,iocharset=utf8"
						end
						system(mkdir)
						# system("mkdir -p '/media/" + k.downcase + "/" + s[0] + "'")
						mount_success = system(mount)
						if system("mountpoint -q '/media/cifs/" + k.downcase + "/" + s[0] + "'") # mount_success # == true
							mount_button.label = mount_string + " lösen" 
							writeable.sensitive = false
							show_button.sensitive = true
							system("exo-open '/media/cifs/" + k.downcase + "/" + s[0] + "'")
						else
							error_dialog(window, extract_lang_string("mount_mo_failed"))
						end
					end
				end
				mount_shares, mount_points, mount_opts = show_mounted_shares
			}
			show_button.signal_connect( "clicked" ) { |w|
				if mount_shares.include?("//" + ip + "/" + s[0])
					system("exo-open '" + mount_points[mount_shares.index("//" + ip + "/" + s[0])] + "'")
				end
			}
			
			button_box = Gtk::HBox.new(false, 1)
			button_box.pack_start(writeable, false, false, 2)
			button_box.pack_start(mount_button, false, false, 2)
			button_box.pack_start(show_button, false, false, 2)
			outer_vbox.pack_start(button_box, false, false, 5)
		}
		# inner_hbox.pack_start(inner_vbox, false, false, 5)
		# outer_vbox.pack_start(inner_hbox, false, false, 5)
		if sharecount == 0
			sorry_label = Gtk::Label.new(extract_lang_string("mount_no_shares"))
			sorry_label.xalign = 0.1
			sorry_label.wrap = true
			sorry_label.width_request = 500
			outer_vbox.pack_start(sorry_label)
		end
		sep = Gtk::HSeparator.new
		outer_vbox.pack_start(sep)
	}
	if smbshares.size < 1
		nothing_found = Gtk::Label.new(extract_lang_string("mount_no_servers"))
		nothing_found.wrap = true
		nothing_found.width_request = 500
		nothing_found.xalign = 0.1
		outer_vbox.pack_start(nothing_found)
	end
	return outer_vbox
end

def show_search_dialog(parent)
	success = false
	smb_user = nil
	smb_password = nil
	dialog = Gtk::Dialog.new(
		extract_lang_string("pw_title"),
		parent,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL ],
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	# New: ask for username and password on the share
	slabel = Gtk::Label.new(extract_lang_string("browse_label"))
	slabel.wrap = true
	slabel.width_request = 300
	sbox = Gtk::VBox.new(false, 5)
	sbox.pack_start(slabel, false, true, 5)
	dialog.vbox.add(sbox)
	ulabel = Gtk::Label.new(extract_lang_string("pw_user"))
	ulabel.width_request = 75
	uentry = Gtk::Entry.new
	smblabel = Gtk::Label.new(extract_lang_string("pw_short"))
	smblabel.width_request = 75
	smbpass = Gtk::Entry.new
	smbpass.visibility = false
	smbbox = Gtk::HBox.new(false, 5)
	smbbox.pack_start(smblabel, false, true, 5)
	smbbox.pack_start(smbpass, true, true, 5)
	ubox = Gtk::HBox.new(false, 5)
	ubox.pack_start(ulabel, false, true, 5)
	ubox.pack_start(uentry, true, true, 5)
	dialog.vbox.add(ubox)
	dialog.vbox.add(smbbox)
	smbpass.signal_connect('activate') {
		dialog.response(Gtk::Dialog::RESPONSE_OK)
	}
	dialog.show_all
	dialog.run do |response|
		if response == Gtk::Dialog::RESPONSE_OK
			smb_user = uentry.text 
			smb_password = smbpass.text
			success = true
			success = false if smb_password.to_s.strip == "" || smb_user.to_s.strip == ""
		end
		# return success, pass.text
		dialog.destroy
	end
	return success, smb_user, smb_password
end

window = Gtk::Window.new(Gtk::Window::TOPLEVEL)
browse_with_pass, default_user, default_pass = show_search_dialog(window)
smbshares, hostdescs, workgroups = get_smb_servers(browse_with_pass, default_user, default_pass)
outer_vbox = build_panel(smbshares, hostdescs, workgroups, window, default_user, default_pass)
window.set_title  extract_lang_string("prog_name")
window.border_width = 10
window.set_size_request(540, 400)
window.signal_connect('delete_event') { 
	# cleanup
	Gtk.main_quit 
}

scroll_pane = Gtk::ScrolledWindow.new
scroll_pane.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
layout_box = Gtk::VBox.new(false, 0)
scroll_pane.add_with_viewport(outer_vbox)
layout_box.pack_start(scroll_pane, true, true, 0)

window.add(layout_box)
window.show_all
Gtk.main

