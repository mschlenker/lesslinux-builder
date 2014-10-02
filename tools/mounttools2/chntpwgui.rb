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

def fill_win_combo(wincombo, usercombo, gobutton)
	@drives = Array.new
	@winparts = Array.new
	@winusers = Array.new
	@samfiles = Hash.new
	gobutton.sensitive = false
	activeitem = 0
	wincombo.append_text(@tl.get_translation("no_windows_partition_found"))
	199.downto(0) { |n|
		begin
			wincombo.remove_text(n)
		rescue
		end
	}
	Dir.entries("/sys/block").each { |l|
		if l =~ /[a-z]$/ 
			begin
				d =  MfsDiskDrive.new(l, true)
				@drives.push(d) 
			rescue 
				$stderr.puts "Failed adding: #{l}"
			end
		end
	}
	Dir.entries("/sys/block").each { |l|
		if ( l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/ )
			begin 
				d =  MfsDiskDrive.new(l, true)
				@drives.push(d) 
			rescue 
				$stderr.puts "Failed adding: #{l}"
			end
		end
	}
	# Now fill each combo box with the respective 
	@drives.each { |d|
		d.partitions.each { |p|
			iswin, winvers = p.is_windows
			if iswin
				@winparts.push(p)
				wincombo.append_text("#{p.device}, #{p.human_size} - #{winvers}")
				auxsam = p.samfile
				@samfiles[p.device] = auxsam 
				@winusers.push(auxsam.read_users)
			end
		}
	}
	if @winparts.size > 0 
		gobutton.sensitive = true 
		wincombo.sensitive = true
		switch_winusers(usercombo, 0, gobutton)
	else
		wincombo.append_text(@tl.get_translation("no_windows_partition_found"))
		wincombo.sensitive = false
	end
	wincombo.active = 0
end

# 

def switch_winusers(usercombo, position, gobutton)
	# Just for layout purpose: Prevent from jumping when changing
	@winusers.each { |w|
		w.each { |u|
			usercombo.append_text("#{u[1]} (0x#{u[0]})")
		}
	}
	usercombo.append_text(@tl.get_translation("could_not_read_sam"))
	usercombo.active = 0
	usercombo.sensitive = false
	return false if @winparts.size < 1
	# Remove everything and add the real stuff
	999.downto(0) { |n|
		begin
			usercombo.remove_text(n)
		rescue
		end
	}
	@winusers[position].each { |u|
		usercombo.append_text("#{u[1]} (0x#{u[0]})")
	}
	gobutton.sensitive = true
	usercombo.sensitive = true
	if @winusers[position].size < 1 
		gobutton.sensitive = false
		usercombo.sensitive = false
		usercombo.append_text(@tl.get_translation("could_not_read_sam"))
	end
	usercombo.active = 0
end

# 

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
tlfile = "chntpwgui.xml"
tlfile = "/usr/share/lesslinux/drivetools/chntpwgui.xml" if File.exists?("/usr/share/lesslinux/drivetools/chntpwgui.xml")
tl = MfsTranslator.new(lang, tlfile)
@tl = tl

# Global variables

@drives = Array.new
@winparts = Array.new
@winusers = Array.new
@samfiles = Hash.new

# Frame for Combobox and Reread-button

cframe = Gtk::Frame.new(tl.get_translation("step1"))
cbox = Gtk::HBox.new(false, 5)
wincombo = Gtk::ComboBox.new
reread = Gtk::Button.new(tl.get_translation("reread"))
cbox.pack_start(wincombo, true, true, 0)
cbox.pack_start(reread, false, true, 0)
cframe.add(cbox)

# Frame for Combobox and Go-Button

uframe = Gtk::Frame.new(tl.get_translation("step2"))
ubox = Gtk::HBox.new(false, 5)
usercombo = Gtk::ComboBox.new
go = Gtk::Button.new(tl.get_translation("go"))
ubox.pack_start(usercombo, true, true, 0)
ubox.pack_start(go, false, true, 0)
uframe.add(ubox)

[ go, reread ].each { |w| w.width_request = 120 } 
[ wincombo, reread, go, usercombo ].each { |w| w.height_request = 32 } 

wincombo.signal_connect("changed") { 
	$stderr.puts "Changed windows installation: " + wincombo.active.to_s
	switch_winusers(usercombo, wincombo.active, go) if  wincombo.active >= 0
}

reread.signal_connect("clicked") {
	fill_win_combo(wincombo, usercombo, go) 
}

go.signal_connect("clicked") {
	$stderr.puts "PARTITION SELECTED: " + @winparts[wincombo.active].device
	$stderr.puts "USER SELECTED: " + @winusers[wincombo.active][usercombo.active][1] 
	$stderr.puts "SAMFILE USED: " + @samfiles[@winparts[wincombo.active].device].partition.device  + " " + @samfiles[@winparts[wincombo.active].device].samfile
	backup = question_dialog(tl.get_translation("backup_title"), tl.get_translation("backup_text"), true)
	success = @samfiles[@winparts[wincombo.active].device].reset(@winusers[wincombo.active][usercombo.active][0], backup)	
	$stderr.puts "SUCCESS: " + success.to_s 
	if success == true
		info_dialog(tl.get_translation("success_title"), tl.get_translation("success_text"))
		Gtk.main_quit
		exit 0 
	else
		error_dialog(tl.get_translation("error_title"), tl.get_translation("error_text"))
	end
}

# VBox for stacking widgets

lvb = Gtk::VBox.new
lvb.pack_start_defaults(cframe)
lvb.pack_start_defaults(uframe)
# lvb.pack_start_defaults(progressframe)

window = Gtk::Window.new
window.signal_connect("delete_event") {
        puts "delete event occurred"
        false
}

window.signal_connect("destroy") {
        puts "destroy event occurred"
        Gtk.main_quit
}

window.border_width = 10
window.set_title(tl.get_translation("head"))
window.window_position = Gtk::Window::POS_CENTER_ALWAYS
# window.deletable = false
# window.decorated = false
# window.width_request = 600
# window.height_request = 400
window.add lvb

fill_win_combo(wincombo, usercombo, go) 

window.show_all
# shutdown.grab_default
# shutdown.grab_focus

Gtk.main