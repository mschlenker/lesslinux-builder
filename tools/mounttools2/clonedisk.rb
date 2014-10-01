#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
require 'MfsDiskDrive.rb'
require 'MfsSinglePartition.rb'
require 'MfsTranslator.rb'

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
tlfile = "clonedisk.xml"
tlfile = "/usr/share/lesslinux/drivetools/clonedisk.xml" if File.exists?("/usr/share/lesslinux/drivetools/clonedisk.xml")
tl = MfsTranslator.new(lang, tlfile)
@tl = tl

@drives = Array.new
@devices = Array.new
@nicedrives = Array.new
@errorcount = 0

def check_source_target(sourcecombo, targetcombo) 
	return true unless ( @devices[sourcecombo.active].device[@devices[targetcombo.active].device] || @devices[targetcombo.active].device[@devices[sourcecombo.active].device] )
	error_dialog(@tl.get_translation("source_target_title"), @tl.get_translation("source_target_text"))
	return false
end

def check_matching_types(sourcecombo, targetcombo) 
	return true if @devices[sourcecombo.active].class == @devices[targetcombo.active].class
	return question_dialog(@tl.get_translation("different_type_title"), @tl.get_translation("different_type_text"), false)
end

def check_sizes(sourcecombo, targetcombo)
	return true if @devices[sourcecombo.active].size <= @devices[targetcombo.active].size
	return question_dialog(@tl.get_translation("too_small_title"), @tl.get_translation("too_small_text"), false)
end

def check_mounted_source(combo)
	return true unless @devices[combo.active].mounted
	return question_dialog(@tl.get_translation("source_mounted_title"), @tl.get_translation("source_mounted_text"), false)
end

def check_mounted_target(combo)
	@devices[combo.active].force_umount 
	return true unless @devices[combo.active].mounted
	error_dialog(@tl.get_translation("target_mounted_title"), @tl.get_translation("target_mounted_text"))
	return false
end

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


def fill_combo(srccombo, tgtcombo, gobutton)
	@drives = Array.new
	@devices = Array.new
	@nicedrives = Array.new
	activeitem = 0
	199.downto(0) { |n|
		begin
			srccombo.remove_text(n)
		rescue
		end
		begin
			tgtcombo.remove_text(n)
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
		srccombo.append_text(nicename) 
		tgtcombo.append_text(nicename) 
		@devices.push(d)
		@nicedrives.push(nicename)
		itemcount += 1
		d.partitions.each { |p|
			unless p.extended
				nicename = @tl.get_translation("partition") + " - /dev/#{p.device} (#{p.human_size}) #{p.fs}"
				srccombo.append_text("\t#{nicename}") 
				tgtcombo.append_text("\t#{nicename}") 
				@devices.push(p) 
				@nicedrives.push(nicename)
				itemcount += 1
			end
		}
	}
	if itemcount == 0
		srccombo.append_text("No usable drives found!")
		srccombo.sensitive = false
		tgtcombo.append_text("No usable drives found!")
		tgtcombo.sensitive = false
		gobutton.sensitive = false
	else
		srccombo.sensitive = true
		tgtcombo.sensitive = true
		gobutton.sensitive = true
	end
	srccombo.active = 0
	tgtcombo.active = 0 
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

def run_clone(source, target, progress)
	puts source.device + " -> " + target.device
	# Calculate size
	puts source.size.to_s 
	chunksize = 64 * 1024 * 1024 
	chunkcount = [ source.size, target.size ].min / chunksize
	puts "Chunksize: " + chunksize.to_s
	puts "Chunkcount: " + chunkcount.to_s 
	puts "Lastchunk: " + ( [ source.size, target.size ].min % chunksize ).to_s 
	tstart = Time.now.to_i 
	tremain = 1_000_000_000_000
	0.upto(chunkcount - 1) { |c|
		while @clone_running == false
			puts "cloning interrupted"
			sleep 0.2
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
		end
		seek = c * 16
		cmd = "dd if=/dev/#{source.device} of=/dev/#{target.device} bs=4M count=16 seek=#{seek.to_s} skip=#{seek.to_s}"
		# cmd = "dd if=/dev/#{source.device} of=/dev/null bs=4M count=16 seek=#{seek.to_s} skip=#{seek.to_s}"
		puts cmd
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
	puts "Delta: " + ( [ source.size, target.size ].min - ( chunkcount * chunksize )).to_s  
	cmd = "dd if=/dev/#{source.device} of=/dev/#{target.device} bs=4M count=16 seek=#{ (chunkcount * 16 ).to_s} skip=#{ (chunkcount * 16 ).to_s}"
	puts cmd
	system(cmd) 
	system("sync") 
	progress.text = "100%"
	progress.fraction = 1.0
end

# Select the drive 

drivebox = Gtk::HBox.new(false, 5)
drivecombo = Gtk::ComboBox.new
go = Gtk::Button.new(tl.get_translation("go"))
go.sensitive = false 

# Button to reread the drivelist

reread = Gtk::Button.new(tl.get_translation("reread"))
driveframe = Gtk::Frame.new(tl.get_translation("frame_source"))
drivebox.pack_start(drivecombo, true, true, 0)
drivebox.pack_start(reread, false, true, 0)
reread.width_request = 100
driveframe.add(drivebox)

# Target drive

targetframe = Gtk::Frame.new(tl.get_translation("frame_target"))
targetcombo = Gtk::ComboBox.new
targetframe.add(targetcombo)

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

[ drivecombo, reread, go, targetcombo ].each { |w| w.height_request = 32 } 

# VBox for stacking widgets

lvb = Gtk::VBox.new
lvb.pack_start_defaults(driveframe)
lvb.pack_start_defaults(targetframe)
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

fill_combo(drivecombo, targetcombo, go)

reread.signal_connect("clicked")  {
	fill_combo(drivecombo, targetcombo, go)
}

@clone_running = false

go.signal_connect("clicked") {
	if @clone_running == true
		@clone_running = false
		# Cancel dialog
		if confirm_stop == true
			puts "Errors: " + @errorcount.to_s
			Gtk.main_quit
			exit 
		else
			@clone_running = true
		end
	else
		# Check that target and source are different
		doclone = check_source_target(drivecombo, targetcombo) 
		# Check for matching types of source and target
		doclone = check_matching_types(drivecombo, targetcombo)  if doclone == true
		# Check sizes of source and target - last partition
		doclone = check_sizes(drivecombo, targetcombo) if doclone == true
		# Check for mounted source
		doclone = check_mounted_source(drivecombo) if doclone == true
		# Check for mounted target
		doclone = check_mounted_target(targetcombo) if doclone == true
		# Now warn
		doclone = question_dialog(@tl.get_translation("clone_warn_title"), @tl.get_translation("clone_warn_text"), false) if doclone == true
		if doclone == true
			@clone_running = true 
			drivecombo.sensitive = false
			targetcombo.sensitive = false
			reread.sensitive = false
			pgbar.text = tl.get_translation("starting")
			go.label = tl.get_translation("stop")
			while (Gtk.events_pending?)
				Gtk.main_iteration
			end
			run_clone(@devices[drivecombo.active], @devices[targetcombo.active], pgbar)
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
