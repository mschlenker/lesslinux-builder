#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
require 'vte'
require 'MfsDiskDrive'
require 'MfsSinglePartition'
require 'MfsTranslator'

def fill_combo(srccombo, gobutton)
	@drives = Array.new
	@devices = Array.new
	@nicedrives = Array.new
	activeitem = 0
	199.downto(0) { |n|
		begin
			srccombo.remove_text(n)
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
	itemcount = 0
	@drives.each{ |d|
		type = "(S)ATA/SCSI" 
		type = "MMC (int/ext)" if d.device =~ /mmcblk/ 
		type = "USB" if d.usb == true
		nicename = "#{type} - /dev/#{d.device} - #{d.vendor} #{d.model} (#{d.human_size})"
		srccombo.append_text(nicename) 
		@devices.push(d)
		@nicedrives.push(nicename)
		itemcount += 1
	}
	if itemcount == 0
		srccombo.append_text("No usable drives found!")
		srccombo.sensitive = false
		gobutton.sensitive = false
	else
		srccombo.sensitive = true
		gobutton.sensitive = true
	end
	srccombo.active = 0
end

def get_free_space(dir)
	free = 0
	IO.popen("df -k #{dir}") { |l|
		while l.gets 
			toks = $_.strip.split
			free = toks[3].to_i * 1024
		end
	}
	return free
end

def get_suffix(vmdk, vdi, vhdx, qcow)
	return "qcow2" if qcow.active?
	return "vhdx" if vhdx.active?
	return "vdi" if vdi.active?
	return "vmdk" 
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

def check_size(disk, dir)
	if disk.size > get_free_space(dir)
		return question_dialog(@tl.get_translation("target_too_small"), @tl.get_translation("target_too_small_long"))
	end
	return true 
end

def check_mounted_source(combo)
	return true unless @devices[combo.active].mounted
	return question_dialog(@tl.get_translation("source_mounted_title"), @tl.get_translation("source_mounted_text"), false)
end

def create_image(format, device, targetfile, pgbar)
	vte = Vte::Terminal.new
	running = true
	vte.signal_connect("child_exited") { running = false }
	@pid = vte.fork_command("/bin/bash", [ "/bin/bash", "vdiskimage-wrapper.sh", format, "/dev/"+ device.device, targetfile] )
	pgbar.text = @tl.get_translation("conversion_running").gsub("PERCENTAGE", "0")
	n = 0
	while running == true
		if (n % 25 == 0) && File.exists?(targetfile)
			percentage = File.size?(targetfile).to_f / device.size.to_f * 100.0
			pgbar.text = @tl.get_translation("conversion_running").gsub("PERCENTAGE", percentage.to_i.to_s)
		end
		pgbar.pulse
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		sleep 0.2 
		n += 1
	end
	exitcode = 255
	pgbar.fraction = 1.0
	if File.exists?(targetfile + ".exit") && File.size(targetfile + ".exit") > 0
		exitcode = File.new(targetfile + ".exit").read.to_i
		File.unlink(targetfile + ".exit")
	end
	if exitcode > 0
		pgbar.text = @tl.get_translation("failed_pgbar")
		error_dialog(@tl.get_translation("failed"), @tl.get_translation("failed_long"))
	else
		pgbar.text = @tl.get_translation("success_pgbar")
		info_dialog(@tl.get_translation("success"), @tl.get_translation("success_long"))
	end
	vte.destroy
end

@drives = Array.new
@devices = Array.new
@nicedrives = Array.new
@running = false
@pid = nil

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
# tlfile = "clonedisk.xml"
# tlfile = "/usr/share/lesslinux/drivetools/clonedisk.xml" if File.exists?("/usr/share/lesslinux/drivetools/clonedisk.xml")
tlfile = "vdiskimage.xml"
tl = MfsTranslator.new(lang, tlfile)
@tl = tl

lvb = Gtk::VBox.new
window = Gtk::Window.new
window.signal_connect("delete_event") {
        puts "delete event occurred"
        false
}

window.signal_connect("destroy") {
        puts "destroy event occurred"
        Gtk.main_quit
}

# Combobox for source selection

drivebox = Gtk::HBox.new(false, 5)
drivecombo = Gtk::ComboBox.new
drivecombo.width_request = 400
go = Gtk::Button.new(tl.get_translation("go"))
go.sensitive = false 

# Button to reread the drivelist

reread = Gtk::Button.new(tl.get_translation("reread"))
driveframe = Gtk::Frame.new(tl.get_translation("frame_source"))
drivebox.pack_start(drivecombo, true, true, 0)
drivebox.pack_start(reread, false, true, 0)
reread.width_request = 100
driveframe.add(drivebox)
lvb.pack_start_defaults driveframe

# Image format

formatframe = Gtk::Frame.new(tl.get_translation("frame_format"))
formatbox = Gtk::VBox.new(false, 2)
vmdk = Gtk::RadioButton.new("VMDK (VMware)")
vdi = Gtk::RadioButton.new(vmdk, "VDI (VirtualBox)")
vhdx = Gtk::RadioButton.new(vmdk, "VHDX (Microsoft Virtual PC)")
qcow = Gtk::RadioButton.new(vmdk, "QCOW2 (Qemu, Xen, KVM)")
[ vmdk, vdi, vhdx, qcow ].each { |f| formatbox.pack_start_defaults(f) } 
formatframe.add(formatbox)
lvb.pack_start_defaults formatframe

# Select the target directory

targetframe = Gtk::Frame.new(tl.get_translation("frame_target"))
targetbutton = Gtk::FileChooserButton.new(tl.get_translation("targetdir"), Gtk::FileChooser::ACTION_SELECT_FOLDER)
targetbutton.current_folder = "/media/disk"
targetframe.add(targetbutton) 
lvb.pack_start_defaults targetframe

# Progress

progressframe = Gtk::Frame.new(tl.get_translation("frame_progress"))
pgbar = Gtk::ProgressBar.new
pgbar.text = tl.get_translation("click_start")
# pgbar.fraction = 0.7
go.width_request = 100
progressbox = Gtk::HBox.new(false, 5)
progressbox.pack_start(pgbar, true, true, 0)
progressbox.pack_start(go, false, true, 0)
progressframe.add(progressbox)
lvb.pack_start_defaults progressframe

window.add(lvb) 
window.set_title(tl.get_translation("title"))
window.window_position = Gtk::Window::POS_CENTER_ALWAYS
# initially read the drivelist
fill_combo(drivecombo, go)

go.signal_connect("clicked") {
	if @running == true
		system("kill -9 #{@pid.to_s}")
	else
		disk = @drives[drivecombo.active]
		dir = targetbutton.filename 
		format = get_suffix(vmdk, vdi, vhdx, qcow)
		targetfile = dir + "/" + disk.device + "." +  format
		if File.exists?(targetfile) 
			error_dialog(@tl.get_translation("target_exists"), @tl.get_translation("target_exists_long").gsub("FILENAME", targetfile))
		elsif check_size(disk, dir) && check_mounted_source(drivecombo)
			[ vmdk, vdi, vhdx, qcow, drivecombo, targetbutton, reread].each { |w| w.sensitive = false } 
			@running = true
			go.label = @tl.get_translation("cancel")
			create_image(format, disk, targetfile, pgbar)
			@running = false
			go.label = tl.get_translation("go")
			[ vmdk, vdi, vhdx, qcow, drivecombo, targetbutton, reread].each { |w| w.sensitive = true } 
		end
	end
}


window.show_all
Gtk.main

