#!/usr/bin/ruby
# encoding: utf-8

require "rexml/document"
require 'gtk2'

class MmmmDriveList
	
	def initialize(doc, langstrings)
		@outer_vbox = Gtk::VBox.new(false, 1)
		@drives = nil
		@drivetabs = Hash.new
		@separators = Hash.new
		@doc = doc
		@langstrings = langstrings
		# reread_drives
		@mountpoints = Hash.new
		populate_vbox
	end
	attr_reader :outer_vbox
	
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
		@doc.root.elements.each("drive") {|d|
			partcount = 0
			@drivetabs[d] = Gtk::HBox.new(false, 1)
			$stderr.puts d.attributes["dev"] + " " + d.attributes["vendor"] + " " + d.attributes["size"].to_s
			if (d.attributes["dev"] =~  /$sr/ )
				pixbuf = icon_theme.load_icon("gnome-dev-dvd", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK)
			elsif (d.attributes["usb"].to_s == true || d.attributes["device"] =~ /mmcblk/ )
				pixbuf = icon_theme.load_icon("gnome-dev-media-sdmmc", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK)
			else
				pixbuf = icon_theme.load_icon("gnome-dev-harddisk", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK)
			end
			img = Gtk::Image.new(pixbuf)
			inner_vbox = Gtk::VBox.new(false, 1)
			desctext = d.attributes['vendor'] + " " + d.attributes['model']
			desctext = desctext + " (" +  d.attributes['hsize'].to_s + ")" unless d.attributes["hsize"].nil?
			ddesc = Gtk::Label.new(desctext)
			ddesc.modify_font fat_font
			inner_vbox.pack_start_defaults ddesc 
			d.elements.each("partition") { |p|
				inner_vbox.pack_start(create_button_box(p, d), false, false, 2)
				partcount += 1
			}
			if partcount > 0
				@drivetabs[d].pack_start_defaults img
				@drivetabs[d].pack_start_defaults inner_vbox
				@outer_vbox.pack_start_defaults @drivetabs[d]
				@separators[d] = Gtk::HSeparator.new
				@outer_vbox.pack_start_defaults @separators[d]
			end
		}
		
	end
	
	def create_button_box(p, d)
		dev_desc = "???"
		if p.attributes["dev"] =~ /^sd[a-z]$/ 
			dev_desc = extract_lang_string("pan_stick")
		elsif p.attributes["dev"] =~ /^sd[a-z][0-9]$/ 
			part_num = p.attributes["dev"].split(/sd[a-z]/)
			dev_desc = extract_lang_string("pan_part") + " " + part_num[1].to_s
		elsif p.attributes["dev"] =~ /^sr[0-9]$/
			dev_desc = extract_lang_string("pan_optical")
		else
			dev_desc = extract_lang_string("pan_part")
		end
		writeable = Gtk::CheckButton.new(extract_lang_string "pan_writable")
		fs = "unknown"
		fs = p.attributes["fs"] unless p.attributes["fs"].nil?
		dev_details = dev_desc + " (" + p.attributes["dev"] + ", " + fs + ")"
		mount_button = Gtk::Button.new(extract_lang_string("pan_layout").gsub("%ACTION%", extract_lang_string("pan_mount")).gsub("%DRIVE%", dev_details)) 
		mount_button.width_request = 260
		mount_button.height_request = 32
		show_button = Gtk::Button.new(extract_lang_string("pan_show"))
		show_button.width_request = 120
		show_button.height_request = 32
		writeable.active = false
		writeable.active = true if ( !p.attributes["mountpoint"].nil? && p.attributes["mountopts"] =~ /rw/ )
		if p.attributes["fs"].to_s == "iso9660"
			writeable.sensitive = false
		end
		if p.attributes["mountpoint"].nil?
			show_button.sensitive = false
			if p.attributes["fs"].nil? # || p.attributes["fs"] == "crypto_LUKS"
				mount_button.sensitive = false
				writeable.sensitive = false
			elsif p.attributes["fs"] == "swap"
				writeable.sensitive = false
				writeable.active = true
			end
		else
			writeable.sensitive = false
			if p.attributes["system"].to_s == "true" 
				mount_button.label = extract_lang_string("pan_sysdrive")
				mount_button.sensitive = false
			else
				mount_button.label = extract_lang_string("pan_layout").gsub("%ACTION%", extract_lang_string("pan_umount")).gsub("%DRIVE%", dev_details)
				# dev_desc + " (" + p[0].gsub("/dev/", "") + ", " + p[1] + ") freigeben"
			end
			@mountpoints[p.attributes["dev"]] = p.attributes["mountpoint"]
		end
		show_button.sensitive = false if p.attributes["fs"] == "swap"
		show_button.sensitive = false if p.attributes["mountpoint"] == "/media/swap"
		show_button.signal_connect( "clicked" ) { |w|
			if ( p.attributes["mountpoint"].nil? == false && system("mountpoint -q \"" + p.attributes["mountpoint"] + "\"") )
				system("Thunar \"" + p.attributes["mountpoint"] + "\" &")
			else
				system("Thunar /media/disk/#{p.attributes['dev']} &" )
			end
		}
		mount_button.signal_connect( "clicked" ) {|w|
			unless @mountpoints.has_key?(p.attributes["dev"]) 
				laxsudo = system("check_lax_sudo")
				success = false
				password = ""
				mode = "ro"
				mode = "rw" if writeable.active?
				mountcommand = "sudo /usr/bin/llmounthelper.sh mount " + p.attributes['dev'] + " " + mode
				if laxsudo == false
					success, password = pwdialog
					mountcommand = "echo '" + password + "' | sudo -S /usr/bin/llmounthelper.sh mount " + p.attributes['dev'] + " " + mode
				end
				if system(mountcommand)
					writeable.sensitive = false
					show_button.sensitive = true unless p.attributes['fs'] == "swap"
					mount_button.label = extract_lang_string("pan_layout").gsub("%ACTION%", extract_lang_string("pan_umount")).gsub("%DRIVE%", dev_details)
					system("Thunar /media/disk/#{p.attributes['dev']} &" ) unless p.attributes['fs'] == "swap"
					@mountpoints[p.attributes["dev"]] = "/media/disk/" + p.attributes['dev'] 
				else
					error_dialog(extract_lang_string("pan_mount_error"))
				end
			else
				if system("sudo /usr/bin/llmounthelper.sh umount #{p.attributes['dev']}")
					writeable.sensitive = true unless p.attributes["fs"] == "iso9660" || p.attributes["fs"] == "swap"
					show_button.sensitive = false
					mount_button.label = extract_lang_string("pan_layout").gsub("%ACTION%", extract_lang_string("pan_mount")).gsub("%DRIVE%", dev_details)
					@mountpoints.delete(p.attributes["dev"]) 
				else
					error_dialog(extract_lang_string("pan_umount_error"))
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
		begin
			return @langstrings[text]
		rescue
			return text
		end
	end
	
	def error_dialog(message)
		dialog = Gtk::MessageDialog.new($main_application_window, 
			Gtk::Dialog::MODAL,
			Gtk::MessageDialog::ERROR,
			Gtk::MessageDialog::BUTTONS_CLOSE,
			message)
		dialog.run
		dialog.destroy
	end

	def pwdialog
		dialog = Gtk::Dialog.new(
			extract_lang_string("pw_title"),
			nil,
			Gtk::Dialog::MODAL,
			[ Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL ],
			[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
		)
		dialog.default_response = Gtk::Dialog::RESPONSE_OK
		question  = Gtk::Label.new(extract_lang_string("pw_desc"))
		question.height_request = 32
		entry_label = Gtk::Label.new(extract_lang_string("pw_password"))

		pass = Gtk::Entry.new
		pass.visibility = false
		pass.signal_connect('activate') {
			#puts pass.text
			dialog.response(Gtk::Dialog::RESPONSE_OK)
			# dialog.destroy
		}
		hbox = Gtk::HBox.new(false, 5)
		hbox.pack_start_defaults(entry_label)
		hbox.pack_start_defaults(pass)
		dialog.vbox.add(question)
		dialog.vbox.add(hbox)
		dialog.show_all
		success = false
		password = ""
		dialog.run do |response|
			if response == Gtk::Dialog::RESPONSE_OK
				success = true
				password = pass.text
			end
			dialog.destroy
		end
		return success, password
	end
end