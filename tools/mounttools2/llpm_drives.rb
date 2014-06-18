#!/usr/bin/ruby
# encoding: utf-8

require "rexml/document"
require 'glib2'
require 'gtk2'
require 'MfsSinglePartition.rb'
require 'MfsDiskDrive.rb'
require 'MfsTranslator.rb'

# Create a pipe menu for openbox. Call via wrapper and include like
#
#<menu id="MmDrives" label="Laufwerke" execute="sudo /usr/bin/llpm_drives" />
#<menu id="root-menu" label="Openbox 3">
#  <separator label="Applications" />
#  <menu id="apps-accessories-menu"/>
#  <menu id="apps-editors-menu"/>
#  <menu id="apps-graphics-menu"/>
#  <menu id="apps-net-menu"/>
#  <menu id="apps-office-menu"/>
#  <menu id="apps-multimedia-menu"/>
#  <menu id="apps-term-menu"/>
#  <menu id="apps-fileman-menu"/>
#  <separator label="LessLinux" />
#  <menu id="MmDrives"/> 
#  <separator label="System" />
#  <menu id="system-menu"/>
#  <separator />
#  <item label="Log Out">
#    <action name="Exit">
#      <prompt>yes</prompt>
#    </action>
#  </item>
#</menu>

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
tl = MfsTranslator.new(lang, "/usr/share/lesslinux/drivetools/llpm_drives.xml")

def get_item(label, action) 
	item = REXML::Element.new "item"
	item.add_attribute("label", label) 
	act = REXML::Element.new "action"
	act.add_attribute("name", "Execute")
	item.add_element act
	cmd = REXML::Element.new "command"
	cmd.add_text action
	act.add_element cmd
	return item
end

doc = REXML::Document.new # (nil, { :respect_whitespace => %w{ script style } } )
root = REXML::Element.new "openbox_pipe_menu"
mct = 0

drives = Array.new
Dir.entries("/sys/block").each { |l|
	drives.push(MfsDiskDrive.new(l, true)) if l =~ /[a-z]$/ 
}
Dir.entries("/sys/block").each { |l|
	drives.push(MfsDiskDrive.new(l, true)) if l =~ /sr[0-9]$/ 
}
internal_items = Array.new
external_items = Array.new
drives.each { |d|
	partcount = 0
	d.partitions.each { |p|
		drive = REXML::Element.new "menu"
		filesys = p.fs.to_s
		filesys = "iso9660" if filesys == "" && p.device =~ /sr[0-9]/
		filesys = "unknown" if filesys == ""
		label = "#{p.device} (#{p.human_size}, #{filesys})"
		label = "#{p.device} (#{p.human_size}, #{filesys}, #{p.label.to_s})" unless p.label.to_s == ""
		label = "#{p.device} (#{p.human_size}, #{tl.get_translation('system_drive')})" if p.system_partition?
		drive.add_attribute("label", label)
		drive.add_attribute("id", "lldrive-" + p.device)
		if p.mount_point.nil?
			drive.add_element get_item(tl.get_translation("mount_ro"), "llpm_mount mount-ro #{p.device} #{filesys}")
			unless p.fs.to_s == "iso9660"
				drive.add_element get_item(tl.get_translation("mount_rw"),"llpm_mount mount-rw #{p.device} #{filesys}" )
			end
		elsif p.system_partition?
			drive.add_element get_item(tl.get_translation("show"),"llpm_mount show #{p.device}" )
		else
			drive.add_element get_item(tl.get_translation("show"),"llpm_mount show #{p.device}" )
			drive.add_element get_item(tl.get_translation("unmount"),"llpm_mount umount #{p.device}" )
			unless p.fs.to_s == "iso9660"
				if p.mount_point[1].include?("ro") 
					drive.add_element get_item(tl.get_translation("mount_rw"), "llpm_mount remount-rw #{p.device} #{filesys}")
				else
					drive.add_element get_item(tl.get_translation("mount_ro"), "llpm_mount remount-ro #{p.device} #{filesys}")
				end
			end
		end
		# root.add drive
		if p.fs.to_s != "" || p.label.to_s != "" || p.device =~ /sr[0-9]/ 
			internal_items.push drive unless d.usb == true
			external_items.push drive if d.usb == true
			if p.mount_point.nil?
				system("mkdir -p /media/disk/#{p.device}") 
				system("chown 1000:1000 /media/disk/#{p.device}")
			end
			partcount += 1
		end
	}
	if partcount > 0
		internal_items.push REXML::Element.new "separator" unless d.usb == true
		external_items.push REXML::Element.new "separator" if d.usb == true
	end
}
if internal_items.size > 0
	intsep = REXML::Element.new "separator"
	intsep.add_attribute("label", tl.get_translation("internal"))
	root.add_element intsep
	internal_items.each{ |i| root.add i }
end
if external_items.size > 0
	extsep = REXML::Element.new "separator"
	extsep.add_attribute("label", tl.get_translation("external"))
	root.add_element extsep
	external_items.each{ |i| root.add i }
end

doc.add root
doc.write($stdout, 4)