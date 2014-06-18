#!/usr/bin/ruby
# encoding: utf-8

require 'gtk2'
require "rexml/document"

# Constants for sizes:

@syssizes = Hash.new
@syssizes["knoppix"] = [ 0, 900_000_000 ]
@syssizes["bank2011"] = [ 400_000_000, 700_000_000 ]
@syssizes["cbsicher"] = [ 0, 1_000_000_000 ]
@syssizes["decleaner"] = [ 200_000_000, 600_000_000 ]
@syssizes["cbrescue"] = [ 0, 650_000_000 ]
@distros = { "knoppix" => "Notfall-Arbeitsplatz (Knoppix)", "bank2011" => "Homebanking Plus", "cbsicher" => "Sicher Surfen",
	"decleaner" => "Antibot-CD 2.0", "cbrescue" => "Notfall-CD" }
@distroorder = [ "cbrescue", "knoppix", "bank2011", "cbsicher", "decleaner" ] 


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

# Functions

def trigger_reboot()
	system("touch /var/run/lesslinux/reboot_me_now")
end

def get_target_selection()
	choicelabel = Gtk::Label.new("Auf welches USB-Laufwerk wollen Sie die Notfall-Security-DVD installieren? Das ausgewählte Laufwerk wird komplett gelöscht. Falls mehrere Laufwerke angezeigt werden, empfehlen wir, einen Schritt zurück gehen und die nicht als Installationsziel vorgesehenen Laufwerke abzuziehen.")
	@drivecombo = Gtk::ComboBox.new
	choicelabel.wrap = true 
	choicelabel.width_request = 450
	@drivecombo.width_request = 360
	@drivelist, @drivehash = fill_choicebox(@drivecombo)
	choicelabel.xalign = 0.1
	choice_vbox = Gtk::VBox.new(false, 5) 
	choice_vbox.pack_start(choicelabel, false, true, 5) 
	@reread = Gtk::Button.new("Neu einlesen")
	@reread.signal_connect("clicked") { @drivelist, @drivehash = fill_choicebox(@drivecombo) } 
	hbox = Gtk::HBox.new(false, 5) 
	hbox.pack_start(@drivecombo, false, true, 5) 
	hbox.pack_start(@reread, false, true, 5) 
	choice_vbox.pack_start(hbox, false, true, 5) 
	return choice_vbox, nil, nil
end

def fill_choicebox(combo)
	# Clear checkbox for disclaimer when rereading
	1000.downto(0) { |n|
		begin
			combo.remove_text(n)
		rescue
		end
	}
	drivelist = Array.new
	drives = get_drivelist()
	drives.keys.sort.each { |d|
		drivelist.push(d)
		combo.append_text(d + " " + drives[d][0] + " " + drives[d][1] + " " + hr_size(drives[d][2]))
	}
	if drivelist.size < 1
		combo.append_text("Kein geeignetes Laufwerk gefunden")
		@assi.set_page_complete(@targetpage, false)
	else
		@assi.set_page_complete(@targetpage, true)
	end
	combo.active = 0
	@selected_drive = 0
	@drivecombo.signal_connect( "changed" ) { |w| 
		check_size
		# @conf_button.sensitive = false
		# @disclaimer.active = false
	}
	# recalculate sizes
	begin
		check_size
	rescue
	end
	#begin
	#	@conf_button.sensitive = false
	#rescue
	#end
	#begin
	#	@disclaimer.active = false
	#rescue
	#end
	# FIXME: Trigger recalculation for next frame!
	return drivelist, drives 
end

def check_mnt(drivelist, drive) 
	drivelist.each { |d|  return true if Regexp.new("^" + drive).match(d.gsub("/dev/", "")) }
	return false
end

def hr_size(size)
	puts size.to_s
	if size.to_i > 7_900_000_000
		return ((size.to_f / 1073741824 ) + 0.5).to_i.to_s + "GB"
	else
		return (size.to_f / 1048576 ).to_i.to_s + "MB"
	end
end

def get_drivelist()
	# { "sda" => [ "WD", "Frobolator", 123456789 ] }
	drivelist = Hash.new
	mounted = Array.new
	IO.popen("cat /proc/mounts") { |line|
		while line.gets 
			ltoks = $_.split
			mounted.push(ltoks[0]) unless ltoks[0].size < 1
		end	
	}
	IO.popen("cat /proc/partitions") { |line|
		while line.gets
			ltoks = $_.split
			unless ltoks.size < 4 || ltoks[3] == "name" || ltoks[3] =~ /[0-9]$/ 
				# puts ltoks[3]
				unless File.new("/sys/block/" + ltoks[3] + "/removable", "r").read.to_i < 1 || check_mnt(mounted, ltoks[3])
					# system("cat /sys/block/" + ltoks[3] + "/removable")
					drivelist[ltoks[3]] = [ File.new("/sys/block/" + ltoks[3] + "/device/vendor", "r").read.strip,
						File.new("/sys/block/" + ltoks[3] + "/device/model", "r").read.strip,
						File.new("/sys/block/" + ltoks[3] + "/size", "r").read.strip.to_i * 512 ]
				end
			end
		end
	}
	return drivelist
end

def get_ossel_selection()
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
	@sizeinfo = Gtk::Label.new
	@sizeinfo.wrap = true
	@sizeinfo.width_request = 450
	vbox.pack_start(@sizeinfo, false, true, 5)
	check_size
	return vbox
end

def check_size()
	checked = 0
	neededsize = 300_000_000
	targetsize = -1
	begin
		targetsize = @drivehash[@drivelist[@drivecombo.active]][2]
	rescue
	end
	# puts targetsize.to_i 
	@distroorder.each { |d|
		# puts d
		if @distrocheck[d].active?
			checked += 1 
			neededsize = neededsize + @syssizes[d][0] + @syssizes[d][1] 
		end
	}
	if checked == 0
		@sizeinfo.text = "Bitte wählen Sie wenigstens ein System aus"
		@assi.set_page_complete(@osselpage, false)
	elsif neededsize * 1.1 > targetsize 
		@sizeinfo.text = "Das ausgewählte Laufwerk ist zu klein - wählen Sie Systeme ab oder ändern Sie das Ziellaufwerk"
		@assi.set_page_complete(@osselpage, false)
	else
		@sizeinfo.text = "Klicken Sie auf \"Weiter\" um die Installation zu starten"
		@assi.set_page_complete(@osselpage, true)
	end
end

def get_instpage
	disc_head = Gtk::Label.new() # ("<b>Haftungsausschluß und Installation</b>")
	disc_head.use_markup = true
	disc_text = Gtk::Label.new("Bei der Installation wird der gesamte Inhalt des USB-Speichers gelöscht und der Datenträger neu formatiert!")
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
	@finished = Gtk::Label.new("Klicken Sie nach der Installation auf \"Anwenden\" um vom USB-Laufwerk zu starten.")
	@finished.wrap = true
	@finished.width_request = 450
	vbox.pack_start(@finished, false, true, 5)
	return vbox
end

def run_installation(progress)
	@reread.sensitive = false
	@drivecombo.sensitive = false
	@distrocheck.each { |d,v| v.sensitive = false }
	@disclaimer.sensitive = false
	percent = 0.0
	@conf_button.sensitive = false
	# num = assistant.current_page
	# page = assistant.get_nth_page(num)
	install_partition(progress)
	install_bootfiles(progress)
	@distroorder.each { |d|
		if @distrocheck[d].active?
			install_knoppix(progress) if d == "knoppix"
			install_cbbank(progress) if d == "bank2011"
			install_cbrescue(progress) if d == "cbrescue"
			install_cbsicher(progress) if d == "cbsicher"
			install_decleaner(progress) if d == "decleaner"
		end
	}
	config_bootloader(progress)
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
	progress.fraction = 1.0 
	progress.text = "Installation abgeschlossen"
	@finished.text = "Klicken Sie auf \"Anwenden\" um von USB zu starten oder gehen Sie zurück, um einen weiteren USB-Speicherstift zu installieren."
	@assi.set_page_complete(@instpage, true)
	@reread.sensitive = true
	@drivecombo.sensitive = true
	@distrocheck.each { |d,v| v.sensitive = true }
	@disclaimer.sensitive = true
	@conf_button.sensitive = true
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
end

# Split the installation in several steps

# Partitioning, filesystems and MBR first

def install_partition(progress)
	progress.text = "Start der Installation"
	targetsize = @drivehash[@drivelist[@drivecombo.active]][2]
	puts "Target has size: " + targetsize.to_s 
	puts "Target is        " + @drivelist[@drivecombo.active]
	ddcommand = "dd if=/dev/zero bs=1024 count=10 of=/dev/" + @drivelist[@drivecombo.active]
	progress.text = "Lösche USB-Speicherstift"
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	system ddcommand
	puts "Deleting drive:  " + ddcommand 
	ptcommand = "parted -s /dev/" + @drivelist[@drivecombo.active] + " unit B mklabel msdos"
	puts "Creating table:  " + ptcommand 
	system ptcommand
	p1min = 0
	p2min = 300_000_000
	# calculate sizes:
	@distroorder.each { |d|
		if @distrocheck[d].active?
			p1min += @syssizes[d][0]
			p2min += @syssizes[d][1]
		end
	}
	p1min = ((p1min / 8192).to_i + 1) * 8192
	p2min = ((p2min / 8192).to_i + 1) * 8192
	progress.text = "Partitioniere USB-Speicherstift"
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	puts "Minimal sizes:  " + p1min.to_s + " " + p2min.to_s 
	p1cmd = "parted -s /dev/" + @drivelist[@drivecombo.active] + " unit B mkpart primary fat32 32256 " + (targetsize - p2min - 1048577).to_s  
	puts "Creating part1: " + p1cmd
	system p1cmd
	p2cmd = "parted -s /dev/" + @drivelist[@drivecombo.active] + " unit B mkpart primary ext2 " + (targetsize - p2min - 1048576).to_s + " " + (targetsize - 1048577).to_s   
	puts "Creating part2: " + p2cmd 
	system p2cmd
	system("parted -s /dev/" + @drivelist[@drivecombo.active] + " unit B set 1 lba  on")
	system("parted -s /dev/" + @drivelist[@drivecombo.active] + " unit B set 2 boot on")
	system("cat /usr/share/syslinux/mbr.bin > /dev/" + @drivelist[@drivecombo.active])
	progress.text = "Erstelle Dateisystem auf Partition 1" 
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	system("mkfs.msdos -F32 /dev/" + @drivelist[@drivecombo.active] + "1")
	progress.text = "Erstelle Dateisystem auf Partition 2" 
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	system("mkfs.ext4 /dev/" + @drivelist[@drivecombo.active] + "2")
	system("mkdir -p /lesslinux/install/target_part1")
	system("mount -t vfat /dev/" + @drivelist[@drivecombo.active] + "1 /lesslinux/install/target_part1")
	system("mkdir -p /lesslinux/install/target_part2")
	system("mount -t ext4 /dev/" + @drivelist[@drivecombo.active] + "2 /lesslinux/install/target_part2")
end

# Now install Knoppix

def install_knoppix(progress)
	puts "Installing Knoppix"
	system("mkdir -p /lesslinux/install/target_part2/5in1/knoppix")
	# Knoppix is 722417225 bytes
	knsize = 722417225
	bs = 1048576
	copied = 0
	while copied <= knsize / bs
		ddcmd = "dd count=1 if=/lesslinux/5in1/5in1/knoppix/KNOPPIX of=/lesslinux/install/target_part2/5in1/knoppix/KNOPPIX bs=1048576 seek=" + 
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
	system("rsync --size-only --inplace -avHP /lesslinux/5in1/5in1/knoppix/ /lesslinux/install/target_part2/5in1/knoppix/")
end

# Generic copy of an ISO

def install_iso(iso, text, progress)
	system("mkdir -p /lesslinux/install/target_part2/5in1")
	fsize = File.stat("/lesslinux/5in1/5in1/" + iso).size
	chunks = (fsize.to_f / 1048576.0).to_i
	chunks += 1 if chunks * 1048576 < fsize
	bs = 1048576
	copied = 0
	while copied < chunks 
		ddcmd = "dd count=1 if=/lesslinux/5in1/5in1/" + iso + " of=/lesslinux/install/target_part2/5in1/" + iso + " bs=1048576 seek=" + 
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

# empty container
def create_empty(file, size, progress)
	bs = 1048576
	copied = 0
	while copied < size 
		ddcmd = "dd count=1 if=/dev/zero of=/lesslinux/install/target_part1/" + file + " bs=1048576 seek=" + copied.to_s
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

# Now install CB Rescue

def install_cbrescue(progress)
        puts "Installing CB Rescue"
	# Copy the content of Windows-Programme to partition 1
	system("mkdir -p /lesslinux/rescloop")
	system("mount -o loop /lesslinux/5in1/5in1/cbrescue.iso /lesslinux/rescloop")
	system("tar -C /lesslinux/rescloop -cf - Windows-Programme | tar -C /lesslinux/install/target_part1 -xf - ")
	system("umount /lesslinux/rescloop")
	install_iso("cbrescue.iso", "Installation der Notfall-CD: ", progress)
end

# Now install CB Bank

def install_cbbank(progress)
	puts "Installing Homebanking Plus"
	# Copy FreeOTFE
	system("mkdir -p /lesslinux/bankloop")
	system("mount -o loop /lesslinux/5in1/5in1/bank2011.iso /lesslinux/bankloop")
	system("tar -C /lesslinux/bankloop -cf - FreeOTFE | tar -C /lesslinux/install/target_part1 -xf - ")
	system("umount /lesslinux/bankloop")
	install_iso("bank2011.iso", "Installation von Homebanking Plus: ", progress)
	# Create the container binary/bank2011.llc
	system("mkdir -p /lesslinux/install/target_part1/binary")
	create_empty("bank2011.vol", 200, progress)
	# Create the container bank2011.vol
	create_empty("binary/bank2011.llc", 200, progress)
end

# Now install Antibot 

def install_decleaner(progress)
	puts "Installing DE Cleaner"
	# Copy virus signatures
	system("mkdir -p /lesslinux/declloop")
	system("mount -o loop /lesslinux/5in1/5in1/decleaner.iso /lesslinux/declloop")
	system("tar -C /lesslinux/declloop -cf - antivir avupdate avupdate.bat | tar -C /lesslinux/install/target_part1 -xf - ")
	system("umount /lesslinux/declloop")
	install_iso("decleaner.iso", "Installation der Antibot-CD 2.0: ", progress)
end

# CB Sicher

def install_cbsicher(progress)
        puts "Installing CB Sicher"
	install_iso("cbsicher.iso", "Installation von Sicher Surfen: ", progress)
	# Create the container cbsicher.llc
	system("mkdir -p /lesslinux/install/target_part2/binary")
	system("dd if=/dev/zero bs=1M count=1 seek=255 of=/lesslinux/install/target_part2/binary/cbsicher.llc")
end

# When finished write the bootloader

def install_bootfiles(progress)
	progress.text = "Installiere Startdateien" 
	while (Gtk.events_pending?)
		Gtk.main_iteration
	end
	system("tar -C /lesslinux/5in1/ -cf - boot | tar -C /lesslinux/install/target_part2 -xf - ")
end

def config_bootloader(progress)
	system("extlinux -i /lesslinux/install/target_part2/boot/isolinux")
	system("cp /lesslinux/install/target_part2/boot/isolinux/isolinux.cfg /lesslinux/install/target_part2/boot/isolinux/extlinux.conf")
	# FIXME: Remove unneeded distros plus installation option from default.cfg
	active_distros = Array.new
	@distroorder.each { |d|
		active_distros.push(d) if @distrocheck[d].active?
	}
	system "sed -i 's/INCLUDE 0bank/# INCLUDE 0bank/g' /lesslinux/install/target_part2/boot/isolinux/default.cfg" unless 
		active_distros.include?("bank2011")
	system "sed -i 's/INCLUDE 0notf/# INCLUDE 0notf/g' /lesslinux/install/target_part2/boot/isolinux/default.cfg" unless 
		active_distros.include?("cbrescue")
	system "sed -i 's/INCLUDE 0knop/# INCLUDE 0knop/g' /lesslinux/install/target_part2/boot/isolinux/default.cfg" unless 
		active_distros.include?("knoppix")
	system "sed -i 's/INCLUDE 0sich/# INCLUDE 0sich/g' /lesslinux/install/target_part2/boot/isolinux/default.cfg" unless 
		active_distros.include?("cbsicher")
	system "sed -i 's/INCLUDE 0decl/# INCLUDE 0decl/g' /lesslinux/install/target_part2/boot/isolinux/default.cfg" unless 
		active_distros.include?("decleaner")
	system "sed -i 's/INCLUDE 0inst/# INCLUDE 0inst/g' /lesslinux/install/target_part2/boot/isolinux/default.cfg"
	# find out uuid 
	uuid = ""
	IO.popen("blkid -o udev /dev/" + @drivelist[@drivecombo.active] + "2") { |l|
		while l.gets
			ltoks = $_.split("=")
			uuid = ltoks[1].strip if ltoks[0] == "ID_FS_UUID" 
		end
	}
	Dir.entries("/lesslinux/install/target_part2/boot/isolinux/").each { |f|
		if f =~ /cfg$/ || f =~ /conf$/ 
			system("sed -i 's/uuid=all/uuid=" + uuid + "/' /lesslinux/install/target_part2/boot/isolinux/" + f) unless uuid.size < 1
		end
	}	
	system("umount /lesslinux/install/target_part2")
	system("umount /lesslinux/install/target_part1")
end

###### 
# Now build the GUI

@assi = Gtk::Assistant.new
@assi.deletable = false

# Erstes Fenster - Start hat immer ID 0

desclabel = Gtk::Label.new("Installieren Sie die COMPUTERBILD Notfall-Security-DVD auf einen USB-Speicherstift. Der Speicherstift wird dabei komplett gelöscht!")
desclabel.wrap = true
dtid = @assi.append_page(desclabel)
@assi.set_page_title(desclabel, "Installation auf USB-Laufwerk")
@assi.set_page_type(desclabel, Gtk::Assistant::PAGE_INTRO)
@assi.set_page_complete(desclabel, true)

# Zweites Fenster - Auswahl des Installationszieles ID 1

@targetpage, drivelist, drivecombo = get_target_selection
tgid = @assi.append_page(@targetpage)
@assi.set_page_title(@targetpage, "Installationsziel")
@assi.set_page_type(@targetpage, Gtk::Assistant::PAGE_CONTENT)
@assi.set_page_complete(@targetpage, true) if @drivelist.size > 0

# Drittes Fenster - Auswahl der Installationssysteme ID 2

@osselpage, osboxes, osmsg = get_ossel_selection
osid = @assi.append_page(@osselpage)
@assi.set_page_title(@osselpage, "Installationssysteme")
@assi.set_page_type(@osselpage, Gtk::Assistant::PAGE_CONTENT)
@assi.set_page_complete(@osselpage, false)

# Viertes Fenster - Disclaimer und Installation

@instpage = get_instpage
inid = @assi.append_page(@instpage)
@assi.set_page_title(@instpage, "Abschluß der Installation")
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

