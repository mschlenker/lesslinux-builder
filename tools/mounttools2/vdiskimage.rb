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
		@drives.push(MfsDiskDrive.new(l, true)) if l =~ /[a-z]$/ 
	}
	Dir.entries("/sys/block").each { |l|
		@drives.push(MfsDiskDrive.new(l, true)) if ( l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/ ) 
	}
	itemcount = 0
	@drives.each{ |d|
		type = "(S)ATA/SCSI" 
		type = "MMC (int/ext)" if d.device =~ /mmcblk/ 
		type = "USB" if d.usb == true
		nicename = @tl.get_translation("disk") + " - #{type} - /dev/#{d.device} - #{d.vendor} #{d.model} (#{d.human_size})"
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

@drives = Array.new
@devices = Array.new
@nicedrives = Array.new

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
tlfile = "clonedisk.xml"
tlfile = "/usr/share/lesslinux/drivetools/clonedisk.xml" if File.exists?("/usr/share/lesslinux/drivetools/clonedisk.xml")
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
window.show_all
Gtk.main

