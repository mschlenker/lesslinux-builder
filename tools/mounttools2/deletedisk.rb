#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
require 'vte'
require 'MfsDiskDrive.rb'
require 'MfsSinglePartition.rb'
require 'MfsTranslator.rb'

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
tlfile = "deletedisk.xml"
tlfile = "/usr/share/lesslinux/drivetools/deletedisk.xml" if File.exists?("/usr/share/lesslinux/drivetools/deletedisk.xml")
tl = MfsTranslator.new(lang, tlfile)
@tl = tl

@devices = Array.new
@drives = Array.new
@nicedrives = Array.new
@rundeletion = false
@errorcount = 0 

# Dialog: Do you really want to delete?

def confirm_dialog(act)
	dialog = Gtk::Dialog.new(
		@tl.get_translation("confirm_title"),
		$mainwindow,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::YES, Gtk::Dialog::RESPONSE_YES ],
		[ Gtk::Stock::NO, Gtk::Dialog::RESPONSE_NO ]
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_NO
	dialog.has_separator = false
	label = Gtk::Label.new
	label.set_markup(@tl.get_translation("confirm_text") + "\n\n<b>#{@nicedrives[act]}</b>")
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

def confirm_stop
	dialog = Gtk::Dialog.new(
		@tl.get_translation("stop_title"),
		$mainwindow,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::YES, Gtk::Dialog::RESPONSE_YES ],
		[ Gtk::Stock::NO, Gtk::Dialog::RESPONSE_NO ]
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_YES
	dialog.has_separator = false
	label = Gtk::Label.new
	label.set_markup(@tl.get_translation("stop_text"))
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

# Dialog: Deletion finished!

def confirm_finished
	dialog = Gtk::Dialog.new(
		@tl.get_translation("done_title"),
		$mainwindow,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_OK
	dialog.has_separator = false
	label = Gtk::Label.new
	label.set_markup(@tl.get_translation("done_text"))
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

def confirm_errors
	dialog = Gtk::Dialog.new(
		@tl.get_translation("error_title"),
		$mainwindow,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_OK
	dialog.has_separator = false
	label = Gtk::Label.new
	label.set_markup(@tl.get_translation("error_text").gsub("ERRORCOUNT", @errorcount.to_s))
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

def confirm_mounted
	dialog = Gtk::Dialog.new(
		@tl.get_translation("mounted_title"),
		$mainwindow,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_OK
	dialog.has_separator = false
	label = Gtk::Label.new
	label.set_markup(@tl.get_translation("mounted_text"))
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

# Function: Delete a selected drive

def run_deletion(dev, progress, tworuns)
	source = "/dev/zero"
	source = "/dev/urandom" if tworuns == true
	runs = 0
	runs = 1 if tworuns == true
	puts dev.device
	# Calculate size
	puts dev.size.to_s 
	puts dev.device.to_s
	chunksize = 64 * 1024 * 1024 
	chunkcount = dev.size / chunksize
	puts "Chunksize: " + chunksize.to_s
	puts "Chunkcount: " + ( dev.size / chunksize ).to_s 
	puts "Lastchunk: " + ( dev.size % chunksize ).to_s 
	0.upto(runs) { |r|
	tstart = Time.now.to_i 
	tremain = 1_000_000_000_000
	0.upto(chunkcount - 1) { |c|
		while @rundeletion == false
			puts "deletion interrupted"
			sleep 0.2
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
		seek = c * 16
		# cmd = "dd if=/dev/#{dev.device} of=/dev/null bs=4M count=16 seek=#{seek.to_s}"
		cmd = "dd if=#{source} of=/dev/#{dev.device} bs=4M count=16 seek=#{seek.to_s}"
		puts cmd
		puts source
		unless system(cmd)
			@errorcount += 1
			puts "Errors: " + @errorcount.to_s
		end
		progress.fraction = c.to_f / chunkcount.to_f 
		progress.text = ( c * 100 / chunkcount ).to_s + "%"  
		tn = Time.now.to_i
		if c > 2
			tchunk =  ( tn.to_f - tstart.to_f ) / c.to_f 
			puts tchunk.to_f.to_s   
			tr = ( ( chunkcount.to_f - c.to_f ) * tchunk.to_f ).to_i
			tremain = tr if (tr < tremain && tr > 0)
			nicetime = tremain.to_s + "s"
			nicetime = ( tremain / 60 ).to_s + "min" if  tremain / 60 > 4
			nicetime = ( tremain / 3600 ).to_s + "hrs" if  tremain / 3600 > 4
			puts nicetime + " remaining" 
			progress.text = ( c * 100 / chunkcount ).to_s + "% - "   + nicetime  + " " + @tl.get_translation("remaining") 
		else
			progress.text = ( c * 100 / chunkcount ).to_s + "%"  
		end
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
	}
	puts "Delta: " + ( dev.size - ( chunkcount * chunksize )).to_s  
	cmd = "dd if=/dev/zero of=/dev/#{dev.device} bs=4M count=16 seek=#{ (chunkcount * 16 ).to_s}"
	puts cmd
	system(cmd) 
	system("sync") 
	progress.text = "100%"
	progress.fraction = 1.0
	}
	run_trim(dev, progress) 
end

def run_trim(dev, progress)
	return false if dev.trim? == false
	return false if dev.trim?.nil?
	run_command(progress, "mkfs.ext4", [ "mkfs.ext4", "-F", "/dev/#{dev.device}"], @tl.get_translation("prepare_trim"))
	system("mkdir /var/run/lesslinux/trim_target")
	system("mount /dev/#{dev.device} /var/run/lesslinux/trim_target")
	run_command(progress, "fstrim", [ "fstrim", "-v", "/var/run/lesslinux/trim_target"], @tl.get_translation("trimming"))
	system("sync")
	system("umount /dev/#{dev.device}")
	system("dd if=/dev/zero bs=1M count=1 of=/dev/#{dev.device}")
	progress.text = @tl.get_translation("trim_done")
	progress.fraction = 1.0
end

def run_command(pgbar, command, args, text)
	puts "Running " + command + " : " + args.join(" ")  
	pgbar.text = text 
	vte = Vte::Terminal.new
	running = true
	vte.signal_connect("child_exited") { running = false }
	vte.fork_command(command, args)
	while running == true
		pgbar.pulse
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		sleep 0.2 
	end
end

# Function: Fill the combo box

def fill_combo(combo, gobutton, default=nil)
	@drives = Array.new
	@devices = Array.new
	@nicedrives = Array.new
	activeitem = 0
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
		nicename = @tl.get_translation("disk") + " - #{type} - /dev/#{d.device} - #{d.vendor} #{d.model} (#{d.human_size})"
		combo.append_text(nicename) 
		@devices.push(d)
		@nicedrives.push(nicename)
		activeitem = itemcount if default == "/dev/#{d.device}" 
		itemcount += 1
		d.partitions.each { |p|
			unless p.extended
				nicename = @tl.get_translation("partition") + " - /dev/#{p.device} (#{p.human_size}) #{p.fs}"
				combo.append_text("\t#{nicename}") 
				@devices.push(p) 
				@nicedrives.push(nicename)
				activeitem = itemcount if default == "/dev/#{p.device}" 
				itemcount += 1
			end
		}
	}
	if itemcount == 0
		combo.append_text("No usable drives found!")
		combo.sensitive = false
		gobutton.sensitive = false
	else
		combo.sensitive = true
		gobutton.sensitive = true
	end
	combo.active = activeitem
end

# Select the drive 

drivebox = Gtk::HBox.new(false, 5)
drivecombo = Gtk::ComboBox.new
go = Gtk::Button.new(tl.get_translation("go"))
go.sensitive = false 

# Button to reread the drivelist

reread = Gtk::Button.new(tl.get_translation("reread"))
reread.signal_connect("clicked")  {
	fill_combo(drivecombo, go)
}
driveframe = Gtk::Frame.new(tl.get_translation("frame_drive"))
drivebox.pack_start(drivecombo, true, true, 0)
drivebox.pack_start(reread, false, true, 0)
reread.width_request = 100
driveframe.add(drivebox)

# Select the method - two runs with random data or one run with zeroes

methodframe = Gtk::Frame.new(tl.get_translation("frame_method"))
radio1 = Gtk::RadioButton.new(tl.get_translation("onerun"))
radio2 = Gtk::RadioButton.new(radio1, tl.get_translation("tworuns"))
methodbox = Gtk::VBox.new(false, 5)
methodbox.pack_start(radio1, true, true, 0)
methodbox.pack_start(radio2, true, true, 0)
methodframe.add(methodbox)

# Progress bar and button

progressframe = Gtk::Frame.new(tl.get_translation("frame_progress")) 
pgbar = Gtk::ProgressBar.new
pgbar.text = tl.get_translation("click_start")
# pgbar.fraction = 0.7

go.width_request = 100
progressbox = Gtk::HBox.new(false, 5)
progressbox.pack_start(pgbar, true, true, 0)
progressbox.pack_start(go, false, true, 0)
progressframe.add(progressbox)

[ drivecombo, reread, go ].each { |w| w.height_request = 32 } 

# VBox for stacking widgets

lvb = Gtk::VBox.new
lvb.pack_start_defaults(driveframe)
lvb.pack_start_defaults(methodframe)
lvb.pack_start_defaults(progressframe)

# Mainwindow

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

fill_combo(drivecombo, go, ARGV[0])
unless ARGV[0].nil? 
	drivecombo.sensitive = false
	reread.sensitive = false
end

go.signal_connect("clicked") {
	drivecombo.sensitive = false
	reread.sensitive = false
	radio1.sensitive = false
	radio2.sensitive = false
	puts "Clicked go:" 
	puts "Do two runs: " + radio2.active?.to_s
	puts drivecombo.active 
	puts "Drive: " + @devices[drivecombo.active].device 
	puts "Nice name: " + @nicedrives[drivecombo.active]
	# ask first:
	if @rundeletion == true
		@rundeletion = false
		if confirm_stop == true
			puts "Errors: " + @errorcount.to_s
			Gtk.main_quit
			exit 
		else
			@rundeletion = true
		end
	elsif confirm_dialog(drivecombo.active) && @rundeletion == false
		@devices[drivecombo.active].force_umount
		if @devices[drivecombo.active].mounted
			confirm_mounted
			if ARGV[0].nil? 
				drivecombo.sensitive = true
				reread.sensitive = true
			end
			radio1.sensitive = true
			radio2.sensitive = true
		else
			@rundeletion = true
			pgbar.text = tl.get_translation("starting")
			go.label = tl.get_translation("stop")
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			run_deletion(@devices[drivecombo.active], pgbar, radio2.active?)
			if @errorcount < 1 
				confirm_finished
			else
				confirm_errors 
			end
			Gtk.main_quit
			exit
		end
	end
}

window.show_all
# shutdown.grab_default
# shutdown.grab_focus

Gtk.main
