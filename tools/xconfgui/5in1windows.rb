#!/usr/bin/ruby
# encoding: utf-8

require 'gtk2'
require "rexml/document"

###### Global variables

@syssizes = Hash.new
@syssizes["knoppix"] = [ 0, 730_000_000 ]
@syssizes["bank2011"] = [ 400_000_000, 1_000_000_000 ]
@syssizes["cbsicher"] = [ 0, 1_000_000_000 ]
@syssizes["decleaner"] = [ 200_000_000, 500_000_000 ]
@syssizes["cbrescue"] = [ 0, 630_000_000 ]
@distros = { "knoppix" => "Notfall-Arbeitsplatz (Knoppix)", "bank2011" => "Homebanking Plus", "cbsicher" => "Sicher Surfen",
	"decleaner" => "Antibot-CD 2.0", "cbrescue" => "Notfall-CD" }
@distroorder = [ "cbrescue", "knoppix", "bank2011", "cbsicher", "decleaner" ] 

@target = nil # device
@installdir = nil # full directory, including mountpoint
@uuids = Hash.new

# Global variables for common use

@selected_drive = nil
@drivehash = Hash.new
@drivelist = Array.new
@selected_distros = Array.new
@drivecombo = nil
@distrocheck = Hash.new
@sizeinfo = nil

# Some GUI elements needed by other functions

@assi = nil
@targetpage = nil
@osselpage = nil
@disclaimer = nil
@reread = nil
@finished = nil

###### Functions

def trigger_reboot()
	system("touch /var/run/lesslinux/reboot_me_now")
end

def find_target() 
	parts = Array.new
	ntfsparts = Array.new
	fatparts = Array.new
	IO.popen("cat /proc/partitions") { |l|
		while l.gets
			ltoks = $_.strip.split
			unless ltoks[3].nil? || ltoks[3] =~ /loop/
				parts.push(ltoks[3])
			end
		end
	}
	parts.each { |p|
		IO.popen("blkid -o udev /dev/" + p) { |l|
			while l.gets
				ltoks = $_.strip.split('=')
				if ltoks[0] == "ID_FS_TYPE"
					ntfsparts.push(p) if ltoks[1] =~ /ntfs/
					fatparts.push(p) if ltoks[1] =~ /fat/
				elsif ltoks[0] == "ID_FS_UUID"
					@uuids[p] = ltoks[1].strip
				end
				
			end
		}
	}
	system("mkdir -p /lesslinux/install/target")
	# puts ntfsparts.join(", ")
	found = false
	ntfsparts.each { |p|
		tdev = nil
		tdir = nil
		system("mount -t ntfs-3g -o ro /dev/" + p + " /lesslinux/install/target")
		[ "2", "4", "6" ].each { |n|
			if found == false
				# system("find /lesslinux/install/target -maxdepth #{n} -type f -name '5in1status.txt' | tail -n1") 
				IO.popen("find /lesslinux/install/target -maxdepth #{n} -type f -name '5in1status.txt' ") { |f|
					while f.gets
						stt = nil
						line = $_.strip
						# s = File.new(line, "r")
						stt = `cat #{line.strip} `.strip # s.read.strip
						# s.close
						system("umount /lesslinux/install/target")
						# return File.dirname(line), p unless stt.to_i > 0
						unless stt.to_i > 0 
							tdev = p
							tdir = File.dirname(line)
							found = true
						end
					end
				}
			end
		}
		# system("killall -9 find")
		system("umount /lesslinux/install/target")
		return tdir, tdev if found == true
	}
	return nil, nil
end

def check_size()
	checked = 0
	# puts targetsize.to_i 
	@distroorder.each { |d|
		# puts d
		if @distrocheck[d].active?
			checked += 1 
		end
	}
	if checked == 0
		@sizeinfo.text = "Bitte wählen Sie wenigstens ein System aus"
		@assi.set_page_complete(@osselpage, false)
	else
		@sizeinfo.text = "Klicken Sie auf \"Vor\" um die Installation zu starten"
		@assi.set_page_complete(@osselpage, true)
	end
end

def get_ossel_selection()
	# lab = Gtk::Label.new("Wählen Sie nun die zu installierenden Systeme aus:")
	lab = Gtk::Label.new("Wählen Sie die zu installierenden COMPUTERBILD-CDs aus:")
	lab.wrap = true
	lab.width_request = 450
	vbox = Gtk::VBox.new(false, 5) 
	vbox.pack_start(lab, false, true, 5) 
	@distrocheck = Hash.new
	@distroorder.each { |d|
		@distrocheck[d] = Gtk::CheckButton.new(@distros[d])
		vbox.pack_start(@distrocheck[d], false, true, 2)
		@distrocheck[d].signal_connect( "toggled" ) { |w| check_size }
	}
	@distrocheck["bank2011"].sensitive = false
	@sizeinfo = Gtk::Label.new
	@sizeinfo.wrap = true
	@sizeinfo.width_request = 450
	vbox.pack_start(@sizeinfo, false, true, 5)
	check_size
	return vbox
end

def get_instpage
	disc_head = Gtk::Label.new() # ("<b>Abschluss der Installation</b>")
	disc_head.use_markup = true
	# disc_text = Gtk::Label.new("Bei der Installation werden Daten auf ein NTFS-Dateisystem geschrieben. Dieses kann beschädigt werden, wenn Windows nicht heruntergefahren, sondern lediglich in den Suspend-to-Disk-Modus versetzt wurde. Weder die Redaktion der Zeitschrift Computer Bild noch die Programmierer der Notfall-Security-DVD übernehmen die Haftung für verlorene Daten.")
	disc_text = Gtk::Label.new "Die COMPUTERBILD-CDs können jetzt auf die Festplatte übertragen werden." 
	disc_text.wrap = true
	disc_text.width_request = 450
	@disclaimer = Gtk::CheckButton.new("Ich erkenne den Haftungsausschluß an.")
	@disclaimer.active = true 
	vbox = Gtk::VBox.new(false, 5) 
	vbox.pack_start(disc_head, false, true, 5)
	vbox.pack_start(disc_text, false, true, 5)
	# vbox.pack_start(@disclaimer, false, true, 5)
	pgbar = Gtk::ProgressBar.new
	pgbar.width_request = 370
	@conf_button = Gtk::Button.new("Installieren")
	@conf_button.sensitive = false
	@conf_button.sensitive = true if @disclaimer.active?
	@conf_button.sensitive = false if @target.nil?
	@disclaimer.signal_connect("clicked") { 
		@conf_button.sensitive = true if @disclaimer.active?
		@conf_button.sensitive = false unless @disclaimer.active?
	}
	@conf_button.signal_connect("clicked") {
		run_installation(pgbar)
	}
	hbox =  Gtk::HBox.new(false, 5) 
	hbox.pack_start(pgbar, false, true, 5)
	hbox.pack_start(@conf_button, false, true, 5)
	vbox.pack_start(hbox, false, true, 5)
	@finished = Gtk::Label.new("Klicken Sie nach der Installation auf \"Anwenden\" um neu zu starten.")
	@finished.wrap = true
	@finished.width_request = 450
	vbox.pack_start(@finished, false, true, 5)
	return vbox
end

def run_installation(progress)
	# @reread.sensitive = false
	# @drivecombo.sensitive = false
	@distrocheck.each { |d,v| v.sensitive = false }
	@disclaimer.sensitive = false
	percent = 0.0
	@conf_button.sensitive = false
	# num = assistant.current_page
	# page = assistant.get_nth_page(num)
	# install_partition(progress)
	# install_bootfiles(progress)
	mount_target
	system("cp /lesslinux/5in1/boot/menu.lst /lesslinux/install/target/menu.lst")
	system("cat /lesslinux/5in1/boot/menu.lst.chromium >> /lesslinux/install/target/menu.lst") if system("test -f /lesslinux/install/target/chromium.lst")
	system("sed -i 's/timeout 0/timeout 500/g' /lesslinux/install/target/menu.lst")
	@distroorder.each { |d|
		if @distrocheck[d].active?
			# @distroorder = [ "cbrescue", "knoppix", "bank2011", "cbsicher", "decleaner" ]
			install_cbrescue(progress) if d == "cbrescue"
			install_knoppix(progress) if d == "knoppix"
			#install_cbbank(progress) if d == "bank2011"
			install_cbsicher(progress) if d == "cbsicher"
			install_decleaner(progress) if d == "decleaner"
		end
	}
	bootpath = @installdir.gsub("/lesslinux/install/target/", "/") + "/boot"
	syspath =  @installdir.gsub("/lesslinux/install/target/", "/") + "/5in1"
	system("sed -i 's%BOOTPATH%#{bootpath}%g' /lesslinux/install/target/menu.lst")
	system("sed -i 's%SYSPATH%#{syspath}%g' /lesslinux/install/target/menu.lst")
	system("sed -i 's%uuid=all%uuid=#{@uuids[@target]}%g' /lesslinux/install/target/menu.lst")
	# config_bootloader(progress)
	system("echo 1 > " + @installdir + "/5in1status.txt")
	while(percent <= 100.0)
		progress.text = "%.0f%% abgeschlossen" % percent
		# progress.fraction = percent / 100.0
		progress.pulse
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		sleep 0.2
		percent += 5.0
	end
	umount_target
	progress.fraction = 1.0 
	progress.text = "Installation abgeschlossen"
	@finished.text = "Entfernen Sie die DVD und klicken Sie auf \"Anwenden\" um den Computer neu zu starten."
	@assi.set_page_complete(@instpage, true)
	# @reread.sensitive = true
	# @drivecombo.sensitive = true
	@distrocheck.each { |d,v| v.sensitive = true }
	@disclaimer.sensitive = true
	@conf_button.sensitive = true
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
end

def install_knoppix(progress)
	puts "Installing Knoppix"
	# Knoppix is 722417225 bytes
	knsize = 722417225
	bs = 1048576
	copied = 0
	while copied <= knsize / bs
		ddcmd = "dd count=1 if=/lesslinux/5in1/5in1/knoppix/KNOPPIX of=" + @installdir + "/5in1/knoppix/KNOPPIX bs=1048576 seek=" + 
			copied.to_s + " skip=" + copied.to_s 
		puts ddcmd
		# sleep 0.05
		system(ddcmd)
		system("sync") if copied % 10 == 0
		frac = (copied.to_f * bs.to_f) / knsize.to_f * 100.0
		progress.text = "Installation von Knoppix: " + frac.to_i.to_s + "%"  
		progress.fraction = frac / 100.0
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		copied += 1
	end
	system("rsync --size-only --inplace -avHP /lesslinux/5in1/5in1/knoppix/ " + @installdir + "/5in1/knoppix/")
	[ "dsk", "bzi" ].each { |s|
		system("cp /lesslinux/5in1/boot/isolinux/knoppix." + s + " " + @installdir + "/boot/") 
	}
	system("cat /lesslinux/5in1/boot/menu.lst.knoppix >> /lesslinux/install/target/menu.lst")
end

def install_iso(iso, text, progress)
	# system("mkdir -p /lesslinux/install/target/5in1")
	fsize = File.stat("/lesslinux/5in1/5in1/" + iso).size
	chunks = (fsize.to_f / 1048576.0).to_i
	chunks += 1 if chunks * 1048576 < fsize
	bs = 1048576
	copied = 0
	while copied < chunks 
		ddcmd = "dd count=1 if=/lesslinux/5in1/5in1/" + iso + " of=" + @installdir + "/5in1/" + iso + " bs=1048576 seek=" + 
			copied.to_s + " skip=" + copied.to_s
		puts ddcmd
		system(ddcmd)
		system("sync") if copied % 10 == 0
		frac = copied.to_f / chunks.to_f * 100.0
		progress.text = text + frac.to_i.to_s + "%"  
		progress.fraction = frac / 100.0
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		copied += 1
	end
end

# Now install CB Rescue

def install_cbrescue(progress)
        puts "Installing CB Rescue"
	# Copy the content of Windows-Programme to partition 1
	# system("mkdir -p /lesslinux/rescloop")
	# system("mount -o loop /lesslinux/5in1/5in1/cbrescue.iso /lesslinux/rescloop")
	# system("tar -C /lesslinux/rescloop -cf - Windows-Programme | tar -C /lesslinux/install/target_part1 -xf - ")
	# system("umount /lesslinux/rescloop")
	install_iso("cbrescue.iso", "Installation der Notfall-CD: ", progress)
	system("cat /lesslinux/5in1/boot/isolinux/rescue/initram.img /lesslinux/5in1/boot/isolinux/rescue/i3101vn.img > " + 
		@installdir + "/boot/cbrescue.dsk")
	system("cp /lesslinux/5in1/boot/isolinux/rescue/l3101vn " + @installdir + "/boot/cbrescue.bzi")
	system("cp /lesslinux/5in1/boot/isolinux/rescue/memdisk " + @installdir + "/boot/")
	system("cp /lesslinux/5in1/boot/isolinux/rescue/memtest.img " + @installdir + "/boot/")
	system("cat /lesslinux/5in1/boot/menu.lst.cbrescue >> /lesslinux/install/target/menu.lst")
end

# Now install Antibot 

def install_decleaner(progress)
	puts "Installing DE Cleaner"
	# Copy virus signatures
	# system("mkdir -p /lesslinux/declloop")
	# system("mount -o loop /lesslinux/5in1/5in1/decleaner.iso /lesslinux/declloop")
	# system("tar -C /lesslinux/declloop -cf - antivir avupdate | tar -C /lesslinux/install/target_part1 -xf - ")
	# system("umount /lesslinux/declloop")
	install_iso("decleaner.iso", "Installation der Antibot-CD 2.0: ", progress)
	system("cat /lesslinux/5in1/boot/isolinux/antibot/initram.img /lesslinux/5in1/boot/isolinux/antibot/i3101vn.img > " + 
		@installdir + "/boot/decleaner.dsk")
	system("cp /lesslinux/5in1/boot/isolinux/antibot/l3101vn " + @installdir + "/boot/decleaner.bzi")
	system("cat /lesslinux/5in1/boot/menu.lst.decleaner >> /lesslinux/install/target/menu.lst")
end

# CB Sicher

def install_cbsicher(progress)
        puts "Installing CB Sicher"
	install_iso("cbsicher.iso", "Installation von Sicher Surfen: ", progress)
	create_empty("5in1/cbsicher.llc", 300, progress)
	# Create the container cbsicher.llc
	# system("mkdir -p /lesslinux/install/target_part2/binary")
	# system("dd if=/dev/zero bs=1M count=1 seek=255 of=/lesslinux/install/target_part2/binary/cbsicher.llc")
	####### Fixme: Fresh kernel
	system("cat /lesslinux/5in1/boot/isolinux/cbsicher/initram.img /lesslinux/5in1/boot/isolinux/cbsicher/i3101np.img > " + 
		@installdir + "/boot/cbsicher.dsk")
	system("cp /lesslinux/5in1/boot/isolinux/cbsicher/l3101np " + @installdir + "/boot/cbsicher.bzi")
	system("cat /lesslinux/5in1/boot/menu.lst.cbsicher >> /lesslinux/install/target/menu.lst")
end

# empty container
def create_empty(file, size, progress)
	bs = 1048576
	copied = 0
	while copied < size 
		ddcmd = "dd count=1 if=/dev/zero of=" + @installdir + "/" + file + " bs=1048576 seek=" + copied.to_s
		puts ddcmd
		system(ddcmd)
		system("sync") if copied % 10 == 0
		frac = copied.to_f / size.to_f * 100.0
		progress.text = "Erstelle Container " + file + ": " + frac.to_i.to_s + "%"  
		progress.fraction = frac / 100.0
		while (Gtk.events_pending?)
			Gtk.main_iteration
		end
		copied += 1
	end
end

def config_bootloader(progress)
	
end

def mount_target
	system("mount -t ntfs-3g -o rw /dev/" + @target + " /lesslinux/install/target")
end

def umount_target
	system("umount /lesslinux/install/target")
end

###### 
# Now build the GUI

@assi = Gtk::Assistant.new
@assi.deletable = false

@installdir, @target = find_target

puts "Target device: " + @installdir.to_s
puts "Target path:   " + @target.to_s

# Erstes Fenster - Start hat immer ID 0

desclabel = Gtk::Label.new("Vollenden Sie die unter Windows begonnene Installation der Notfall-Security-DVD. Nach Abschluss der Installation können Sie das Notfall-Security-System ohne DVD im Laufwerk starten.")
desclabel.wrap = true
dtid = @assi.append_page(desclabel)
@assi.set_page_title(desclabel, "Abschluss der Installation")
@assi.set_page_type(desclabel, Gtk::Assistant::PAGE_INTRO)
@assi.set_page_complete(desclabel, true)

# Zweites Fenster - Auswahl der Installationssysteme ID 2

@osselpage, osboxes, osmsg = get_ossel_selection
osid = @assi.append_page(@osselpage)
@assi.set_page_title(@osselpage, "Installationssysteme")
@assi.set_page_type(@osselpage, Gtk::Assistant::PAGE_CONTENT)
@assi.set_page_complete(@osselpage, false)

# Drittes Fenster - Disclaimer und Installation

@instpage = get_instpage
inid = @assi.append_page(@instpage)
@assi.set_page_title(@instpage, "Abschluss der Installation")
@assi.set_page_type(@instpage, Gtk::Assistant::PAGE_CONFIRM)
@assi.set_page_complete(@instpage, false)

# Handlers

@assi.signal_connect('close')   { |w|
	puts "cleanup and reboot here"
	trigger_reboot
	Gtk.main_quit
}

@assi.signal_connect('cancel')   { |w|
	puts "cleanup and reboot here"
	trigger_reboot
	Gtk.main_quit 
}


@assi.set_title("Installation") 
@assi.border_width = 10
@assi.set_size_request(500, 350)
@assi.show_all
Gtk.main
