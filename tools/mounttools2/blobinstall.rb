#!/usr/bin/ruby

require 'rexml/document'
require 'glib2'
require 'gtk2'
require 'vte'
require 'MfsTranslator.rb'
require 'optparse'

def is_installed?(dirs, files) 
	dirs.each { |d|
		return true if File.directory?(d)
	}
	files.each { |f|
		return true if File.file?(f)
	}
	return false
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

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
tlfile = "blobinstall.xml"
tlfile = "/usr/share/lesslinux/drivetools/blobinstall.xml" if File.exists?("/usr/share/lesslinux/drivetools/blobinstall.xml")
tl = MfsTranslator.new(lang, tlfile)

checkedblobs = Array.new
hiddenblobs = Array.new
opts = OptionParser.new 
opts.on('-c', '--check', :REQUIRED )    { |i| checkedblobs = i.split(",") }
opts.on('-h', '--hide', :REQUIRED )    { |i| hiddenblobs = i.split(",") }
opts.parse!

blobxmls = Array.new
checkboxes = Array.new
checkxmls = Hash.new
installable = 0

Dir.entries("/usr/share/lesslinux/blob").each { |f|
	if f =~ /\.xml$/
		blobxmls.push(REXML::Document.new(File.new("/usr/share/lesslinux/blob/#{f}")))
	end
}

# Build a window

# Frame for selection of Blobs
bframe = Gtk::Frame.new(tl.get_translation("select"))
bbox = Gtk::VBox.new(false, 5)
blobxmls.each { |x|
	unless hiddenblobs.include?(x.root.elements["pkg"].attributes["name"])
		name = nil
		ttip = nil
		x.root.elements.each("name") { |n|
			name = n.text if n.attributes["lang"] == lang
		}
		x.root.elements.each("description") { |n|
			ttip = n.text if n.attributes["lang"] == lang
		}
		name = x.root.elements["name[@lang='en']"].text if name.nil?
		ttip = x.root.elements["description[@lang='en']"].text if ttip.nil?
		checkfiles = x.root.elements["pkg"].attributes["checkfiles"].split
		checkdirs = x.root.elements["pkg"].attributes["checkdirs"].split
		butt = Gtk::CheckButton.new(name, false)
		if is_installed?(checkdirs, checkfiles)
			butt.active = true 
			butt.sensitive = false
		else
			checkxmls[butt] = x
			butt.active = true if checkedblobs.include?(x.root.elements["pkg"].attributes["name"]) 
			installable += 1
		end
		# butt.tooltip(ttip)
		checkboxes.push(butt)
		bbox.pack_start_defaults(butt)
	end
}
bframe.add(bbox)

# Frame for installation progress
iframe = Gtk::Frame.new(tl.get_translation("progress"))
vte = Vte::Terminal.new
vte.set_font("Fixed 13", Vte::TerminalAntiAlias::FORCE_DISABLE)
vte.height_request = 150
iframe.add(vte)
# vte.fork_command("top")

window = Gtk::Window.new
window.signal_connect("delete_event") {
        puts "delete event occurred"
        false
}

window.signal_connect("destroy") {
        puts "destroy event occurred"
        Gtk.main_quit
}

lvb = Gtk::VBox.new
lvb.pack_start_defaults(bframe)
lvb.pack_start_defaults(iframe)
bbox = Gtk::HBox.new

cancel = Gtk::Button.new(Gtk::Stock::CANCEL)
bbox.pack_start_defaults(cancel)
apply = Gtk::Button.new(Gtk::Stock::APPLY)
bbox.pack_start_defaults(apply)
lvb.pack_start_defaults(bbox)

apply.signal_connect("clicked") {
	apply.sensitive = false
	cancel.sensitive = false
	instcount = 0
	successful = 0
	checkboxes.each { |c|
		if c.active? && c.sensitive?
			instcount += 1
			x = checkxmls[c]
			installer = x.root.elements["pkg"].attributes["installer"]
			running = true
			vte.signal_connect("child_exited") { running = false }
			vte.fork_command(installer)
			while running == true
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				sleep 0.2 
			end
			checkfiles = x.root.elements["pkg"].attributes["checkfiles"].split
        		checkdirs = x.root.elements["pkg"].attributes["checkdirs"].split
			if is_installed?(checkdirs, checkfiles)
				successful +=1 
				c.sensitive = false
			else
				name = x.root.elements["pkg"].attributes["name"]
				info_dialog(tl.get_translation("failed"), tl.get_translation("failed_long").gsub("NAME",name) )
			end
		end
	}
	if instcount == 0
		info_dialog( tl.get_translation("noselect"), tl.get_translation("noselect_long") )
		apply.sensitive = true
        	cancel.sensitive = true
	elsif instcount > successful
		info_dialog( tl.get_translation("instfailed"), tl.get_translation("instfailed_long") )
                apply.sensitive = true
                cancel.sensitive = true
	else
		info_dialog( tl.get_translation("successful"), tl.get_translation("successful_long"))
		Gtk.main_quit
	end
}

cancel.signal_connect("clicked") {
	Gtk.main_quit
}

window.border_width = 10
window.width_request = 600 
window.set_title("LessLinux BLOB installer")
window.window_position = Gtk::Window::POS_CENTER_ALWAYS
window.add lvb

if installable < 1
	info_dialog( tl.get_translation("nothing"), tl.get_translation("nothing_long"))
	apply.sensitive = false
	exit 0
	# Gtk.main_quit
else
	unless system("mountpoint -q /lesslinux/blobpart")
		info_dialog( tl.get_translation("usb"), tl.get_translation("usb_long"))
	end
end

window.show_all
Gtk.main

