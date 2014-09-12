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

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
tl = MfsTranslator.new(lang, "/usr/share/lesslinux/drivetools/llpm_drives.xml")
xmldrives = ` sudo xmldrivelist.sh ` 
# xmldrives = ` ruby -I. xmldrivelist.rb ` 
indoc = REXML::Document.new(xmldrives)

outdoc = REXML::Document.new # (nil, { :respect_whitespace => %w{ script style } } )
root = REXML::Element.new "openbox_pipe_menu"
mct = 0

internal_items = Array.new
external_items = Array.new

indoc.root.elements.each("drive") {|d|
	partcount = 0
	d.elements.each("partition") { |p|
		drive = REXML::Element.new "menu"
		filesys = p.attributes["fs"].to_s
		filesys = "unknown" if filesys == ""
		label = "#{p.attributes['dev']} (#{p.attributes['hsize'].to_s}, #{filesys})"
		label = "#{p.attributes['dev']} (CD/DVD)" if p.attributes['dev'] =~ /sr[0-9]/ 
		label = "#{p.attributes['dev']} (#{p.attributes['hsize'].to_s}, #{filesys}, #{p.attributes['label'].to_s})" unless p.attributes['label'].to_s == ""
		label = "#{p.attributes['dev']} (#{p.attributes['hsize'].to_s}, #{tl.get_translation('system_drive')})" if p.attributes['system'].to_s == "true" 
		drive.add_attribute("label", label)
		drive.add_attribute("id", "lldrive-" + p.attributes['dev'])
		if p.attributes['mountpoint'].nil?
			drive.add_element get_item(tl.get_translation("mount_ro"), "llmountandopen.sh mount #{p.attributes['dev']} ro")
			unless p.attributes['dev'] =~ /sr[0-9]/  || p.attributes['fs'].to_s == "iso9660" || p.attributes['fs'].to_s == "udf" 
				drive.add_element get_item(tl.get_translation("mount_rw"), "llmountandopen.sh mount #{p.attributes['dev']} rw")
			end
		elsif p.attributes['system'].to_s == 'true'
			drive.add_element get_item(tl.get_translation("show"),"thunar #{p.attributes['mountpoint']}" )
		else
			drive.add_element get_item(tl.get_translation("show"),"thunar #{p.attributes['mountpoint']}" )
			drive.add_element get_item(tl.get_translation("unmount"),"llmountandopen.sh umount #{p.attributes['dev']}" )
		end
		unless p.attributes['fs'].to_s =~  /swap/ || ( p.attributes['fs'].to_s =~ /crypto_LUKS/ && p.attributes['mountpoint'] == "/media/swap" ) || p.attributes['fs'].to_s == "" 
			if d.attributes['usb'].to_s == "true" 
				external_items.push drive
			else
				internal_items.push drive
			end
			partcount += 1 
		end
	}
	if partcount > 0
		unless d.attributes['usb'].to_s == 'true'
			internal_items.push REXML::Element.new "separator" 
		else
			external_items.push REXML::Element.new "separator"
		end
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

outdoc.add root
outdoc.write($stdout, 4)
