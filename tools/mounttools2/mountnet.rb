#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
# require 'MfsDiskDrive.rb'
# require 'MfsSinglePartition.rb'
require 'MfsTranslator.rb'

def error_dialog(title, text) 
	dialog = Gtk::Dialog.new(
		title,
		$mainwindow,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_OK
	dialog.has_separator = false
	label = Gtk::Label.new
	label.set_markup(text)
	label.wrap = true
	image = Gtk::Image.new(Gtk::Stock::DIALOG_ERROR, Gtk::IconSize::DIALOG)
	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image)
	hbox.pack_start_defaults(label)
	dialog.vbox.add(hbox)
	dialog.show_all
	dialog.run { |resp|
		dialog.destroy
		return true
	}
end

def info_dialog(title, text) 
	dialog = Gtk::Dialog.new(
		title,
		$mainwindow,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_OK
	dialog.has_separator = false
	label = Gtk::Label.new
	label.set_markup(text)
	label.wrap = true
	image = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image)
	hbox.pack_start_defaults(label)
	dialog.vbox.add(hbox)
	dialog.show_all
	dialog.run { |resp|
		dialog.destroy
		return true
	}
end

def question_dialog(title, text, default=false)
	dialog = Gtk::Dialog.new(
		title,
		$mainwindow,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::YES, Gtk::Dialog::RESPONSE_YES ],
		[ Gtk::Stock::NO, Gtk::Dialog::RESPONSE_NO ]
	)
	if default == true
		dialog.default_response = Gtk::Dialog::RESPONSE_YES
	else
		dialog.default_response = Gtk::Dialog::RESPONSE_NO
	end
	dialog.has_separator = false
	label = Gtk::Label.new
	label.set_markup(text)
	label.wrap = true
	image = Gtk::Image.new(Gtk::Stock::DIALOG_WARNING, Gtk::IconSize::DIALOG)
	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image)
	hbox.pack_start_defaults(label)
	dialog.vbox.add(hbox)
	dialog.show_all
	dialog.run { |resp|
		case resp
		when Gtk::Dialog::RESPONSE_YES
			dialog.destroy
			return true
		else
			dialog.destroy
			return false
		end
	}
end

def check_validity(path)
	protopath = path.split("://")
	protos = [ "smb", "cifs", "http", "https" ]
	return false unless protos.include?(protopath[0])
	return false if protopath[1].to_s == ""
	if protopath[0] == "smb" || protopath[0] == "cifs"
		tuple = protopath[1].split("/")
		return false if tuple[0].to_s == "" || tuple[1].to_s == ""
	end
	if protopath[0] == "http" || protopath[0] == "https"
		tuple = protopath[1].split("/")
		return false if tuple[0].to_s == ""
	end
	return true
end

def get_empty_mount(parent) 
	system("mkdir -p '#{parent}'") 
	return parent unless system("mountpoint '#{parent}'")
	0.upto(99) { |n|
		unless system("mountpoint '#{parent}-#{n.to_s}'")
			system("mkdir -p '#{parent}-#{n.to_s}'")
			return  "#{parent}-#{n.to_s}" 
		end
	}
	return nil 
end

def try_to_mount(path, user, password, readwrite=false)
	if check_validity(path) == false
		error_dialog( @tl.get_translation("pathhead"), @tl.get_translation("pathbody") )
		return false
	end
	rwstr = "ro"
	rwstr = "rw" if readwrite == true
	if path =~ /^http\:\/\// || path =~ /^https\:\/\//
		protopath = path.split("://")
		hostfolder = protopath[1].split("/")
		subdir = get_empty_mount("/media/webdav/#{hostfolder[0]}")
		if path =~ /^https\:\/\//
			return false unless question_dialog( @tl.get_translation("certhead"), @tl.get_translation("certbody") ) 
		end
		system("echo -e '#{user}\n#{password}\ny' | LANG=en_GB.UTF-8 LANGUAGE=en mount.davfs -o #{rwstr},uid=1000,gid=1000,dir_mode=755,file_mode=644 \"#{path}\" \"#{subdir}\"") 
		if system("mountpoint '#{subdir}'")
			system("nohup su surfer -c \"Thunar '#{subdir}'\" &")
			# system("top &")
			Gtk.main_quit 
		else
			error_dialog( @tl.get_translation("mntfailedhead"), @tl.get_translation("mntfailedbody") )
		end
	else
		puts "CIFS mount requested" 
		protopath = path.split("://")
		hostfolder = protopath[1].split("/")
		if system("mountpoint \"/media/cifs/#{hostfolder[0]}/#{hostfolder[1]}\"")
			error_dialog( @tl.get_translation("alreadyhead"), @tl.get_translation("alreadybody") )
			return false
		end
		system("mkdir -p \"/media/cifs/#{hostfolder[0]}/#{hostfolder[1]}\"")
		system("chown 1000:1000 \"/media/cifs/#{hostfolder[0]}/#{hostfolder[1]}\"")
		if user.strip == "" || password.strip == ""
			system("mount.cifs -o '#{rwstr},uid=1000,gid=1000,file_mode=0644,dir_mode=0755,nounix,guest,iocharset=utf8' '//#{hostfolder[0]}/#{hostfolder[1]}' '/media/cifs/#{hostfolder[0]}/#{hostfolder[1]}'")
		else
			system("mount.cifs -o '#{rwstr},uid=1000,gid=1000,file_mode=0644,dir_mode=0755,nounix,user=#{user},pass=#{password},iocharset=utf8' '//#{hostfolder[0]}/#{hostfolder[1]}' '/media/cifs/#{hostfolder[0]}/#{hostfolder[1]}'")
		end
		if system("mountpoint '/media/cifs/#{hostfolder[0]}/#{hostfolder[1]}'")
			system("nohup su surfer -c 'Thunar \"/media/cifs/#{hostfolder[0]}/#{hostfolder[1]}\"' &")
			# system("top &") 
			Gtk.main_quit 
		else
			error_dialog( @tl.get_translation("mntfailedhead"), @tl.get_translation("mntfailedbody") )
		end
	end
end

#

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
tlfile = "mountnet.xml"
tlfile = "/usr/share/lesslinux/drivetools/mountnet.xml" if File.exists?("/usr/share/lesslinux/drivetools/mountnet.xml")
tl = MfsTranslator.new(lang, tlfile)
@tl = tl

# 

ltab = Gtk::Table.new(5, 2, false) # , Gtk::FILL|Gtk::EXPAND, 5, 5 ) 
plab = Gtk::Label.new(@tl.get_translation("path"))
pent = Gtk::Entry.new
pent.width_request = 250
ulab = Gtk::Label.new(@tl.get_translation("user"))
uent = Gtk::Entry.new
uent.width_request = 250
slab = Gtk::Label.new(@tl.get_translation("password"))
sent = Gtk::Entry.new
sent.visibility = false
sent.width_request = 250
rocheck = Gtk::CheckButton.new(@tl.get_translation("readwrite"))
gobutton = Gtk::Button.new(@tl.get_translation("go"))
gobutton.image = Gtk::Image.new(Gtk::Stock::APPLY, Gtk::IconSize::BUTTON)

ltab.attach(plab, 0, 1, 0, 1, Gtk::FILL|Gtk::EXPAND,Gtk::FILL|Gtk::EXPAND, 3, 3 )
ltab.attach(pent, 1, 2, 0, 1, Gtk::FILL|Gtk::EXPAND,Gtk::FILL|Gtk::EXPAND, 3, 3 )
ltab.attach(ulab, 0, 1, 1, 2, Gtk::FILL|Gtk::EXPAND,Gtk::FILL|Gtk::EXPAND, 3, 3 )
ltab.attach(uent, 1, 2, 1, 2, Gtk::FILL|Gtk::EXPAND,Gtk::FILL|Gtk::EXPAND, 3, 3 )
ltab.attach(slab, 0, 1, 2, 3, Gtk::FILL|Gtk::EXPAND,Gtk::FILL|Gtk::EXPAND, 3, 3 )
ltab.attach(sent, 1, 2, 2, 3, Gtk::FILL|Gtk::EXPAND,Gtk::FILL|Gtk::EXPAND, 3, 3 )
ltab.attach(rocheck, 0, 2, 3, 4, Gtk::FILL|Gtk::EXPAND,Gtk::FILL|Gtk::EXPAND, 3, 3 )
ltab.attach(gobutton, 0, 2, 4, 5, Gtk::FILL|Gtk::EXPAND,Gtk::FILL|Gtk::EXPAND, 3, 3 )

gobutton.signal_connect("clicked") {
	try_to_mount(pent.text.strip, uent.text.strip, sent.text.strip, rocheck.active?)  
}

pent.signal_connect("activate") { uent.grab_focus }
uent.signal_connect("activate") { sent.grab_focus }
sent.signal_connect("activate") {
	try_to_mount(pent.text.strip, uent.text.strip, sent.text.strip, rocheck.active?)  
}

@window = Gtk::Window.new
@window.border_width = 10
@window.set_title(tl.get_translation("head"))
@window.window_position = Gtk::Window::POS_CENTER_ALWAYS
# window.deletable = false
# window.decorated = false
# window.width_request = 600
# window.height_request = 400
@window.add ltab 
@window.show_all
Gtk.main






