#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
require 'MfsDiskDrive.rb'
require 'MfsSinglePartition.rb'
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


# 
def reread_drives(combo, go) 
	@allparts = Array.new
	@mountableparts = Array.new
	drives = Array.new
	199.downto(0) { |n|
		begin
			combo.remove_text(n)
		rescue
		end
	}
	Dir.entries("/sys/block").each { |l|
			if l =~ /[a-z]$/ 
				begin
					d =  MfsDiskDrive.new(l, true)
					drives.push(d) 
				rescue 
					$stderr.puts "Failed adding: #{l}"
				end
			end
	}
	Dir.entries("/sys/block").each { |l|
			if ( l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/ )
				begin 
					d =  MfsDiskDrive.new(l, true)
					drives.push(d) 
				rescue 
					$stderr.puts "Failed adding: #{l}"
				end
			end
	}
	drives.each { |d|
		d.partitions.each { |p|
			@allparts.push p
			if ( p.fs =~ /ntfs/ || p.fs =~ /fat/ ) && p.hibernated? == false && p.mount_point.nil? 
				type = "(S)ATA/SCSI" 
				type = "MMC (int/ext)" if d.device =~ /mmcblk/ 
				type = "USB" if d.usb == true
				@mountableparts.push p 
				desc = " (#{p.label})" unless p.label == ""
				desc = ""
				iswin, winvers = p.is_windows
				desc = " (#{winvers})" if iswin == true
				combo.append_text "#{type} - #{d.vendor} #{d.model} #{p.device} (#{p.human_size}) #{p.fs}#{desc}"
			end
		}
	}
	if @mountableparts.size < 1
		combo.append_text(@tl.get_translation("nosuitable"))
		combo.sensitive = false
		go.sensitive = false
	else
		combo.sensitive = true
		go.sensitive = true
	end
	combo.active = 0 
end

def mount_all(combo)
	system("mkdir -p /media/backup")
	system("mkdir -p /media/disk")
	system("chown 1000:1000 /media/backup")
	p = @mountableparts[combo.active]
	p.mount("rw", "/media/backup", 1000, 1000)
	@allparts.each { |p|
		if p.mount_point.nil?
			unless system("mountpoint  /media/disk/#{p.device}")
				system("mkdir -p /media/disk/#{p.device}")
				system("chown 1000:1000 /media/disk/#{p.device}")
				p.mount("ro", "/media/disk/#{p.device}", 1000, 1000)
				system("rmdir /media/disk/#{p.device}") unless system("mountpoint /media/disk/#{p.device}")
			end
		end
	}
	system("nohup su surfer -c 'Thunar \"/media/backup\"' &")
	system("nohup su surfer -c 'Thunar \"/media/disk\"' &")
	Gtk.main_quit 
end

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
tlfile = "mountall.xml"
tlfile = "/usr/share/lesslinux/drivetools/mountall.xml" if File.exists?("/usr/share/lesslinux/drivetools/mountall.xml")
tl = MfsTranslator.new(lang, tlfile)
@tl = tl

# Global variables

@allparts = Array.new
@mountableparts = Array.new 

# Frame for Combobox and Reread-button

cbox = Gtk::HBox.new(false, 5)
partcombo = Gtk::ComboBox.new
reread = Gtk::Button.new(tl.get_translation("reread"))
cbox.pack_start(partcombo, true, true, 0)
cbox.pack_start(reread, false, true, 0)

# Frame for Combobox and Go-Button

go = Gtk::Button.new(tl.get_translation("go"))
go.image = Gtk::Image.new(Gtk::Stock::APPLY, Gtk::IconSize::BUTTON)
desc = Gtk::Label.new
desc.wrap = true 
[ reread, partcombo ].each { |w| w.height_request = 32 } 
[ go, desc ].each { |w| w.width_request = 500 }
desc.set_markup(@tl.get_translation("choose"))
lobox = Gtk::VBox.new(false, 5)
lobox.pack_start(desc, true, true, 0)
lobox.pack_start(cbox, true, true, 0)
lobox.pack_start(go, true, true, 0)

@window = Gtk::Window.new
@window.border_width = 10
@window.set_title(tl.get_translation("head"))
@window.window_position = Gtk::Window::POS_CENTER_ALWAYS
# window.deletable = false
# window.decorated = false
# window.width_request = 600
# window.height_request = 400
@window.add lobox

reread_drives(partcombo, go) 

go.signal_connect("clicked") { mount_all(partcombo) } 
reread.signal_connect("clicked") { reread_drives(partcombo, go)  }

@window.show_all
if system("mountpoint /media/backup")
	error_dialog(@tl.get_translation("alreadyhead"), @tl.get_translation("alreadybody") )
	exit 1 
end

@window.show_all
Gtk.main





