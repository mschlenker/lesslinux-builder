#!/usr/bin/ruby
# encoding: utf-8

require "rexml/document"
require 'gtk2'

class MmmmDriveList
	
	def initialize
		@outer_vbox = Gtk::VBox.new(false, 1)
		@drives = nil
		@drivetabs = Hash.new
		@separators = Hash.new
		reread_drives
		populate_vbox
	end
	attr_reader :outer_vbox
	
	def reread_drives
		@drives = Array.new
		Dir.entries("/sys/block").each { |l|
			@drives.push(MfsDiskDrive.new(l, true)) if l =~ /[a-z]$/ 
		}
		Dir.entries("/sys/block").each { |l|
			@drives.push(MfsDiskDrive.new(l, true)) if l =~ /sr[0-9]$/ 
		}
	end
	
	def populate_vbox
		icon_theme = Gtk::IconTheme.default
		fat_font = Pango::FontDescription.new("Sans Bold")
		@drivetabs.each { |k, v|
			v.destroy
			@drivetabs.delete k
		}
		@separators.each { |k, v|
			v.destroy
			@separators.delete k
		}
		@drives.each { |d|
			@drivetabs[d] = Gtk::HBox.new(false, 1)
			$stderr.puts d.device + " " + d.vendor + " " + d.size.to_s
			pixbuf = icon_theme.load_icon("gnome-dev-harddisk", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK)
			img = Gtk::Image.new(pixbuf)
			@drivetabs[d].pack_start_defaults img
			@outer_vbox.pack_start_defaults @drivetabs[d]
			inner_vbox = Gtk::VBox.new(false, 1)
			ddesc = Gtk::Label.new("#{d.vendor} #{d.model} (#{d.human_size})")
			ddesc.modify_font fat_font
			inner_vbox.pack_start_defaults ddesc 
			d.partitions.each { |p|
				inner_vbox.pack_start(create_button_box(p, d), false, false, 2)
			}
			@drivetabs[d].pack_start_defaults inner_vbox
			@separators[d] = Gtk::HSeparator.new
			@outer_vbox.pack_start_defaults @separators[d]
		}
		
	end
	
	def create_button_box(p, d)
		dev_desc = "???"
				if p.device =~ /^sd[a-z]$/ 
					dev_desc = extract_lang_string("pan_stick")
				elsif p.device =~ /^sd[a-z][0-9]$/
					part_num = p.device.split(/sd[a-z]/)
					dev_desc = extract_lang_string("pan_part") + " " + part_num[1].to_s
				elsif p.device =~ /^sr[0-9]$/ || p.device =~ /^scd[0-9]$/ || p.device =~ /^cdrom/ 
					dev_desc = extract_lang_string("pan_optical")
				end
				writeable = Gtk::CheckButton.new(extract_lang_string "pan_writable")
				dev_details = dev_desc + " (" + p.device + ", " + p.fs.to_s + ")"
				mount_button = Gtk::Button.new(extract_lang_string("pan_layout").gsub("%ACTION%", extract_lang_string("pan_mount")).gsub("%DRIVE%", dev_details)) 
				mount_button.width_request = 260
				mount_button.height_request = 32
				show_button = Gtk::Button.new(extract_lang_string("pan_show"))
				show_button.width_request = 120
				show_button.height_request = 32
				writeable.active = false
				writeable.active = true if ( !p.mount_point.nil? && p.mount_point[1].include?("rw")  )
				if p.fs.to_s == "iso9660"
					writeable.sensitive = false
				end
				if p.mount_point.nil?
					show_button.sensitive = false
				else
					writeable.sensitive = false
					if p.system_partition? 
						mount_button.label = extract_lang_string("pan_sysdrive")
						mount_button.sensitive = false
					else
						mount_button.label = extract_lang_string("pan_layout").gsub("%ACTION%", extract_lang_string("pan_umount")).gsub("%DRIVE%", dev_details)
						# dev_desc + " (" + p[0].gsub("/dev/", "") + ", " + p[1] + ") freigeben"
					end
				end
				show_button.signal_connect( "clicked" ) { |w|
					system("Thunar " + p.mount_point[0] + " &")
				}
				mount_button.signal_connect( "clicked" ) {|w|
					if p.mount_point.nil?
						mode = "ro"
						mode = "rw" if writeable.active? 
						mount_res = p.mount(mode)
						if mount_res == true
							writeable.sensitive = false
							show_button.sensitive = true
							mount_button.label = extract_lang_string("pan_layout").gsub("%ACTION%", extract_lang_string("pan_umount")).gsub("%DRIVE%", dev_details)
							system("Thunar " + p.mount_point[0] + " &" )
						else
							# FIXME! Add Error dialog again!
							# error_dialog(extract_lang_string("pan_mount_error"))
						end
					else
						umount_res = p.umount
						if umount_res == true
							writeable.sensitive = true unless p.fs == "iso9660" 
							show_button.sensitive = false
							mount_button.label = extract_lang_string("pan_layout").gsub("%ACTION%", extract_lang_string("pan_mount")).gsub("%DRIVE%", dev_details)
						else
							# FIXME! Add Error dialog again!
							# error_dialog(extract_lang_string("pan_umount_error"))
						end
					end
				}
				button_box = Gtk::HBox.new(false, 1)
				button_box.pack_start(writeable, false, false, 2)
				button_box.pack_start(mount_button, false, false, 2)
				button_box.pack_start(show_button, false, false, 2)
				return button_box
	end
	
	def extract_lang_string(text)
		return text
	end
	
end