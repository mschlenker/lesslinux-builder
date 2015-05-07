#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
require "rexml/document"
require 'fileutils'
require 'MfsDiskDrive.rb'
require 'MfsSinglePartition.rb'
require 'MfsTranslator'
require 'digest/sha1'
require 'vte'
 
$vsscount = 0
# $vssmounts = Array.new
 
lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
tlfile = "vshadowgui.xml"
tl = MfsTranslator.new(lang, tlfile)
@tl = tl
 
@drives = Array.new

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

explainframe = Gtk::Frame.new(tl.get_translation("frame_explanation"))
explainlabel = Gtk::Label.new
explainlabel.wrap = true
explainlabel.width_request = 400
explainlabel.set_markup(tl.get_translation("text_explanation"))
explainframe.add(explainlabel) 
lvb.pack_start_defaults explainframe
 
gobutton = Gtk::Button.new(tl.get_translation("mount"))
gobutton.width_request = 400
progressframe = Gtk::Frame.new(tl.get_translation("frame_progress"))
progressbox = Gtk::HBox.new(false, 5) 
progressbox.pack_start(gobutton, false, true, 0)
progressframe.add(progressbox)
lvb.pack_start_defaults progressframe
 
gobutton.signal_connect('clicked') {
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
	if $vsscount < 1
		# Mount all
		@drives.each { |d|
			d.partitions.each { |p|
				if p.vss?
					$vsscount += 1
					p.vss_mount_all 
				end
			}
		}
		# change label
		if $vsscount > 0
			gobutton.label = tl.get_translation("umount")
			system("nohup su surfer -c \"thunar /media/vss\" &") 
			# open file manager
		end
	else
		# Unmount all
		@drives.each { |d|
			d.partitions.each { |p|
				if p.vss?
					p.vss_umount_all 
				end
			}
		}
		$vsscount = 0
		# change label if successful 
		gobutton.label = tl.get_translation("mount")
	end
}

window.add(lvb) 
window.set_title(tl.get_translation("title"))
window.window_position = Gtk::Window::POS_CENTER_ALWAYS

window.show_all
Gtk.main
