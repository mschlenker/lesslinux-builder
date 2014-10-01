#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
require 'vte'
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

def fill_drive_combo(combobox, gobutton, tl)
	gobutton.sensitive = false
	combobox.sensitive = false
	sizes = calculate_min_size 
	puts sizes.join(", ") 
	@drives = Array.new
	199.downto(0) { |n|
                begin
                        combobox.remove_text(n)
                rescue
                end
        }
	drives = Array.new
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
	drives.each { |d|
		unless d.mounted == true
			@drives.push d if d.usb == true && d.size > sizes[0] 
			puts d.device + " " + d.usb.to_s 
		end
	}
	@drives.each { |d|
		nicename = "/dev/#{d.device} - #{d.vendor} #{d.model} (#{d.human_size})"
		combobox.append_text(nicename) 
	}
	combobox.append_text tl.get_translation("no_drive_found") if @drives.size < 1
	combobox.active = 0
	gobutton.sensitive = true if @drives.size > 0
	combobox.sensitive = true if @drives.size > 0

end

def calculate_min_size 
	sysmount = ""
	[ "/lesslinux/cdrom", "/lesslinux/isoloop" ].each { |m|
		sysmount = m if system("mountpoint -q #{m}")
	}
	if sysmount == ""
		error_dialog( @tl.get_translation("no_system_title"), @tl.get_translation("no_system_found"))
		exit 1 
	end
	sysdev = ` df -k #{sysmount} | tail -n1 `.strip.split[0].to_s
	isosize = ` df -k #{sysmount} | tail -n1 `.strip.split[2].to_i * 1024  
	efisize = ` ls -lak #{sysmount}/boot/efi/efi.img `.strip.split[4].to_i 
	bootsize = ` du -k #{sysmount}/boot | tail -n1 `.strip.split[0].to_i * 1024
	padsize = 1024 ** 2 * 64 
	minsize = isosize + bootsize + efisize + padsize
	puts "#{minsize.to_s}: #{isosize.to_s} #{bootsize.to_s} #{efisize.to_s} #{padsize.to_s}"
	isoblocks = isosize / ( 1024 ** 2 * 8 ) + 1
	bootblocks = bootsize / ( 1024 ** 2 * 8 ) + 4
	efiblocks = efisize / ( 1024 ** 2 * 8 ) + 1
	return minsize, isoblocks, bootblocks, efiblocks, sysdev, sysmount 
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

def run_installation(tgt, language, contsizes, pgbar, check=false) 
	sizes = calculate_min_size
	checklist = Array.new
	bootstart = sizes[1] * 8388608 
	efistart = ( sizes[1] + sizes[2] ) * 8388608
	bootend = efistart - 1  
	efiend = ( sizes[1] + sizes[2] + sizes[3]) * 8388608 - 1
	# blank the fist few MB
	# ddstr = "dd if=/dev/zero of=/dev/#{tgt.device} bs=1024 count=1024"
	run_command(pgbar, "dd", [ "dd", "if=/dev/zero", "of=/dev/#{tgt.device}", "bs=1024", "count=1024" ] , @tl.get_translation("preparing")) 
	# puts ddstr 
	# system ddstr 
	# blank the last few MB
	tgtblocks = tgt.size / 1024 - 1024 
	puts tgtblocks.to_s 	
	# ddstr = "dd if=/dev/zero of=/dev/#{tgt.device} bs=1024 seek=#{tgtblocks.to_s}"
	# puts ddstr 
	# system ddstr 
	run_command(pgbar, "dd", [ "dd", "if=/dev/zero", "of=/dev/#{tgt.device}", "bs=1024", "seek=#{tgtblocks.to_s}" ] , @tl.get_translation("preparing")) 
	
	# Copy the ISO image
	0.upto(sizes[1] - 1) { |b|
		system("rm /var/run/lesslinux/copyblock.bin")
		system("rm /var/run/lesslinux/checkblock.bin")
		system("dd if=#{sizes[4]} of=/var/run/lesslinux/copyblock.bin bs=8388608 count=1 skip=#{b.to_s}")
		md5in = ` md5sum /var/run/lesslinux/copyblock.bin `.strip.split[0] 
		md5out = ''
		tries = 0
		matched = false
		while tries < 9 && matched == false 
			system("dd of=/dev/#{tgt.device} if=/var/run/lesslinux/copyblock.bin bs=8388608 count=1 seek=#{b.to_s}")
			system("sync")
			system("dd if=/dev/#{tgt.device} of=/var/run/lesslinux/checkblock.bin bs=8388608 count=1 skip=#{b.to_s}")
			md5out = ` md5sum /var/run/lesslinux/checkblock.bin `.strip.split[0]
			if md5in == md5out 
				matched = true
			else
				puts "ERROR WRITING #{b.to_s} - TRY #{tries.to_s}"
			end
			tries += 1 
		end
			
		# ddstr = "dd if=#{sizes[4]} of=/dev/#{tgt.device} bs=8388608 count=1 seek=#{b.to_s} skip=#{b.to_s}" 
		# puts ddstr 
		# system ddstr 
		percentage = b * 100 / ( sizes[1] - 1 ) 
		pgbar.text =  @tl.get_translation("installsys") + " - #{percentage.to_s}%"
		pgbar.fraction = b.to_f / ( sizes[1] - 1 ).to_f 
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
	}
	system("rm /var/run/lesslinux/copyblock.bin")
	system("rm /var/run/lesslinux/checkblock.bin")
	
	# Blank the first 32k 
	system("dd if=/dev/zero bs=8192 count=4 of=/dev/#{tgt.device}")
	# Create the boot partition legacy
	run_command(pgbar, "parted", [ "parted", "-s", "/dev/#{tgt.device}", "unit", "B", "mklabel", "gpt" ] , @tl.get_translation("partitioning")) 
	run_command(pgbar, "parted", [ "parted", "-s", "/dev/#{tgt.device}", "unit", "B", "mkpart", "primary", "ext2", "#{bootstart}", "#{bootend}" ] , @tl.get_translation("partitioning")) 
	run_command(pgbar, "parted", [ "parted", "-s", "/dev/#{tgt.device}", "unit", "B", "set", "1", "legacy_boot", "on" ] , @tl.get_translation("partitioning")) 
	run_command(pgbar, "parted", [ "parted", "-s", "/dev/#{tgt.device}", "unit", "B", "mkpart", "primary", "fat32", "#{efistart}", "#{efiend}" ] , @tl.get_translation("partitioning")) 
	run_command(pgbar, "parted", [ "parted", "-s", "/dev/#{tgt.device}", "unit", "B", "set", "2", "boot", "on" ] , @tl.get_translation("partitioning")) 
	# tar the content of the legacy boot part 
	run_command(pgbar, "mkfs.ext2", [ "mkfs.ext2", "/dev/#{tgt.device}1" ] , @tl.get_translation("write_boot")) 
	system("mkdir -p /var/run/lesslinux/install_boot")
	system("mount -t ext4 /dev/#{tgt.device}1 /var/run/lesslinux/install_boot")
	run_command(pgbar, "rsync", [ "rsync", "-avHP", "#{sizes[5]}/boot", "/var/run/lesslinux/install_boot/" ] , @tl.get_translation("write_boot")) 
	system("chmod -R 0644 /var/run/lesslinux/install_boot/")
	run_command(pgbar, "dd", [ "dd", "if=#{sizes[5]}/boot/efi/efi.img", "of=/dev/#{tgt.device}2" ], @tl.get_translation("write_boot")) 
	system("mkdir -p /var/run/lesslinux/install_efi")
	system("mount -t vfat /dev/#{tgt.device}2 /var/run/lesslinux/install_efi")
	# Find and move config files 
	cfgfiles = Array.new
	IO.popen("find /var/run/lesslinux/install_boot/boot -name '*.cfg'") { |line|
		while line.gets
			cfgfiles.push $_.strip
		end
	}
	IO.popen("find /var/run/lesslinux/install_efi -name '*.conf'") { |line|
		while line.gets
			cfgfiles.push $_.strip
		end
	}
	cfgfiles.push("/var/run/lesslinux/install_boot/boot/isolinux/extlinux.conf") if File.exists? ("/var/run/lesslinux/install_boot/boot/isolinux/extlinux.conf") 
	cfgfiles.each { |fname|
		puts "Editing: " + fname 
		system("cp -v #{fname}.#{language} #{fname}") if File.exists?("#{fname}.#{language}") 
		system("sed -i 's/homecont=[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9]/homecont=#{contsizes.min.to_s}-#{contsizes.max.to_s}/g' #{fname}") if contsizes.max > 0 
		if tgt.size > 7_000_000_000
			system("sed -i 's/swapsize=[0-9][0-9][0-9][0-9]/swapsize=1024 /g' #{fname}")
			system("sed -i 's/blobsize=[0-9][0-9][0-9][0-9]/blobsize=1536 /g' #{fname}")
		elsif tgt.size > 3_000_000_000
			system("sed -i 's/swapsize=[0-9][0-9][0-9][0-9]/swapsize=512 /g' #{fname}")
			system("sed -i 's/blobsize=[0-9][0-9][0-9][0-9]/blobsize=768 /g' #{fname}")
		end
		system("rm #{fname}") if fname =~ /boot0x80\.cfg$/ 
	}
	system("cp -v /var/run/lesslinux/install_boot/boot/isolinux/{isolinux.cfg,extlinux.conf}") unless File.exists? ("/var/run/lesslinux/install_boot/boot/isolinux/extlinux.conf") 
	# Write syslinux
	system("extlinux --install /var/run/lesslinux/install_boot/boot/isolinux") 
	system("umount /var/run/lesslinux/install_boot")
	system("umount /var/run/lesslinux/install_efi")
	# Write the compat MBR
	sysstr = "dd if=/usr/share/syslinux/gptmbr.bin of=/dev/#{tgt.device}"	
	puts sysstr
	system sysstr
	pgbar.fraction = 1.0
	pgbar.text =  @tl.get_translation("install_finished") 
	info_dialog( @tl.get_translation("finished_title"), @tl.get_translation("finished_text") ) 
end

# 

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
tlfile = "usbinstall.xml"
tlfile = "/usr/share/lesslinux/drivetools/usbinstall.xml" if File.exists?("/usr/share/lesslinux/drivetools/usbinstall.xml")
tl = MfsTranslator.new(lang, tlfile)
@tl = tl
@langsel = [ "de - Deutsch", "en - English", "es - Spanish", "fr - French", "it - Italiano", "nl - Nederlands", "pl - Polish", "pt - Portuguese", "ru - Russian" ] 

# Global variables

@drives = Array.new

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
ubox = Gtk::VBox.new(false, 5)
langcombo = Gtk::ComboBox.new
lindex = 1
lct = 0
@langsel.each { |l|
	langcombo.append_text(l)
	lindex = lct if l =~ Regexp.new("^#{lang}")
	lct += 1 
}
langcombo.active = lindex 
ubox.pack_start(langcombo, false, true, 0)
hbox = Gtk::HBox.new(false, 0)
hcheck = Gtk::CheckButton.new(tl.get_translation("createhome"))
hcheck.active = true
hmin = Gtk::Entry.new
hmin.width_chars = 4
hmax = Gtk::Entry.new
hmax.width_chars = 5
hmin.text = "512"
hmax.text = "2048"
hupto = Gtk::Label.new tl.get_translation("upto")
hunit = Gtk::Label.new "MB"
hbox.pack_start(hcheck, false, false, 2)
hbox.pack_start(hmin, false, false, 2)
hbox.pack_start(hupto, false, false, 2)
hbox.pack_start(hmax, false, false, 2)
hbox.pack_start(hunit, false, false, 2)
ubox.pack_start(hbox, false, false, 0)
uframe.add(ubox)

# Frame for progressbar

pframe = Gtk::Frame.new(tl.get_translation("step3"))
pbox = Gtk::HBox.new(false, 5)
pgbar = Gtk::ProgressBar.new
pgbar.width_request = 380
pgbar.text = tl.get_translation("start_help")
pbox.pack_start(pgbar, false, true, 0)
go = Gtk::Button.new(tl.get_translation("install"))
pbox.pack_start(go, false, false, 0)
pframe.add pbox 

[ reread, go, langcombo ].each { |w| w.height_request = 32 }
[ reread, go ].each { |w| w.width_request = 150 } 

# VBox for stacking widgets

lvb = Gtk::VBox.new
lvb.pack_start_defaults(cframe)
lvb.pack_start_defaults(uframe)
lvb.pack_start_defaults(pframe)
# lvb.pack_start_defaults(progressframe)

window = Gtk::Window.new

hcheck.signal_connect("clicked") {
	[ hmax, hmin ].each { |h| h.sensitive = hcheck.active? }
}

reread.signal_connect("clicked") { fill_drive_combo(wincombo, go, tl) }

go.signal_connect("clicked") {
	contsize = [ 0, 0 ]
	install_prereqs = true
	if hcheck.active? == true
		contsize = [ hmin.text.to_i , hmax.text.to_i ]
		if contsize.min < 256
			install_prereqs = false
			error_dialog(tl.get_translation("container_size_title"), tl.get_translation("container_size_text") )
		end
	end
	if install_prereqs == true && question_dialog(tl.get_translation("really_install"), tl.get_translation("really_description"))
		[ wincombo, langcombo, reread, go, hmin, hmax, hcheck ].each { |w| w.sensitive = false } 
		run_installation(@drives[wincombo.active], @langsel[langcombo.active][0..1] , contsize, pgbar )
		[ wincombo, langcombo, reread, go, hmin, hmax, hcheck ].each { |w| w.sensitive = true } 
	end
}	

window.signal_connect("delete_event") {
        puts "delete event occurred"
        false
}

window.signal_connect("destroy") {
        puts "destroy event occurred"
        Gtk.main_quit
}

# cancel.signal_connect("clicked") { Gtk.main_quit } 

window.border_width = 10
window.set_title(tl.get_translation("head"))
window.window_position = Gtk::Window::POS_CENTER_ALWAYS
# window.deletable = false
# window.decorated = false
# window.width_request = 600
# window.height_request = 400
window.add lvb

fill_drive_combo(wincombo, go, tl)

window.show_all
# shutdown.grab_default
# shutdown.grab_focus

Gtk.main
