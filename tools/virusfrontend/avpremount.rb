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
def count_mount
	mounted = 0
	IO.popen("cat /proc/mounts") { |line|
		while line.gets
			ltoks = $_.strip.split
			mounted += 1 if ltoks[1] =~ /^\/media\/disk/ 
		end
	}
	return mounted
end

def mount_all(rw=false)
	drives = Array.new
	Dir.entries("/sys/block").each { |l|
			if l =~ /[a-z]$/ || l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/
				begin
					d =  MfsDiskDrive.new(l, true)
					drives.push(d) 
				rescue 
					$stderr.puts "Failed adding: #{l}"
				end
			end
	}
	rwmode = "ro"
	rwmode = "rw" if rw == true
	drives.each { |d|
		d.partitions.each { |p|
			if ( p.fs =~ /^fat/i || p.fs =~ /ntfs/i ) && p.mount_point.nil? 
				system("mkdir -p /media/disk/#{p.device}")
				system("chown 1000:1000 /media/disk/#{p.device}")
				p.mount(rwmode, "/media/disk/#{p.device}", 1000, 1000)
			end
		}
	}
end

exit 0 if count_mount > 0

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
tlfile = "avpremount.xml"
tlfile = "/usr/share/lesslinux/virusfrontend/avpremount.xml" if File.exists?("/usr/share/lesslinux/virusfrontend/avpremount.xml")
tl = MfsTranslator.new(lang, tlfile)
@tl = tl

# Frame for Combobox and Go-Button

go = Gtk::Button.new(tl.get_translation("go"))
go.image = Gtk::Image.new(Gtk::Stock::APPLY, Gtk::IconSize::BUTTON)
desc = Gtk::Label.new
desc.wrap = true 
[ go, desc ].each { |w| w.width_request = 400 }
desc.set_markup(@tl.get_translation("choose"))
roauto = Gtk::RadioButton.new(@tl.get_translation("roauto"))
rwauto = Gtk::RadioButton.new(roauto, @tl.get_translation("rwauto"))
manu = Gtk::RadioButton.new(roauto, @tl.get_translation("manu"))

lobox = Gtk::VBox.new(false, 5)
lobox.pack_start(desc, true, true, 0)
lobox.pack_start(roauto, true, true, 0)
lobox.pack_start(rwauto, true, true, 0)
lobox.pack_start(manu, true, true, 0)
lobox.pack_start(go, true, true, 0)

go.signal_connect("clicked") {
	if roauto.active? == true || rwauto.active? == true
		mount_all(rwauto.active?)
		if count_mount < 1
			error_dialog(@tl.get_translation("stillnohead"), @tl.get_translation("stillnobody"))
			system("nohup su surfer -c /usr/bin/mmmmng.sh &")
		end
	else
		system("nohup su surfer -c /usr/bin/mmmmng.sh &")
	end
	Gtk.main_quit
}

@window = Gtk::Window.new
@window.border_width = 10
@window.set_title(tl.get_translation("head"))
@window.window_position = Gtk::Window::POS_CENTER_ALWAYS
# window.deletable = false
# window.decorated = false
# window.width_request = 600
# window.height_request = 400
@window.add lobox
@window.show_all
Gtk.main

