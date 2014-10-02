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
tlfile = "initial_system_check.xml"
tlfile = "/usr/share/lesslinux/drivetools/initial_system_check.xml" if File.exists?("/usr/share/lesslinux/drivetools/initial_system_check.xml")
tl = MfsTranslator.new(lang, tlfile)

drives = Array.new
show_dialog = false

Dir.entries("/sys/block").each { |l|
	if l =~ /[a-z]$/ || l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/ 
		begin
			d =  MfsDiskDrive.new(l, true)
			drives.push(d) 
		rescue 
			$stderr.puts "Failed adding: #{l}"
		end
	end
}

is_hibernated = false
imsm_found = false
badmem = false
squasherror = false
smartfail = false 
toohot = false

drives.each { |d|
	if d.hibernated? == true
		is_hibernated = true
		show_dialog = true
	end
	if d.imsm? == true 
		imsm_found = true
		show_dialog = true
	end
	smart_support, smart_info, smart_errors = d.error_log 
	if smart_errors.size > 0
		smartfail = true
		show_dialog = true 
	end
}

if File.exists?("/var/run/lesslinux/cpuburn.failed")
	toohot = true
	show_dialog = true 
end

dmesg = "dmesg"
dmesg = "cat /var/run/lesslinux/fake_dmesg.txt" if File.exists?("/var/run/lesslinux/fake_dmesg.txt")

IO.popen(dmesg) { |l|
	while l.gets
		puts $_.strip
		if $_ =~ / bad mem addr /
			badmem = true
			show_dialog = true
		end
		if $_ =~ /squashfs error/i
			unless $_ =~ /find a squashfs superblock/i
				squasherror = true
				show_dialog = true
			end 
		end
	end
}

if show_dialog == true
        puts "OK, showing this dialog!"
else
        puts "No bad memory found."
	puts "No IMSM drive found."
	puts "No hibernated windows found."
	puts "No squashfs errors found."
	puts "No SMART error found."
	puts "Not too hot."
	exit 0
end

system("xsetroot -solid red")

icon_theme = Gtk::IconTheme.default
table = Gtk::Table.new(8, 2, false)
warnlab = Gtk::Label.new
warnlab.set_markup("<span weight='bold' size='large'>" + tl.get_translation("head") + "</span>")
warnlab.width_request = 785
table.attach(warnlab, 0, 2, 0, 1, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 15)

# Label IMSM

imsmlab = Gtk::Label.new
imsmlab.set_markup("<b>" + tl.get_translation("imsm_head") +  "</b>\n\n" + tl.get_translation("imsm_text"))
imsmlab.wrap = true
imsmlab.width_request = 730
imsmbuf = icon_theme.load_icon("drive-harddisk", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK)
imsmimg = Gtk::Image.new(imsmbuf)
imsmimg.set_alignment(0,0.5)

if imsm_found == true
        table.attach(imsmlab, 1, 2, 1, 2, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 15)
        table.attach(imsmimg, 0, 1, 1, 2, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 15)
end

# Label hibernation

hiberlab = Gtk::Label.new
hiberlab.set_markup("<b>" + tl.get_translation("hibernated_head") +  "</b>\n\n" + tl.get_translation("hibernated_text"))
hiberlab.wrap = true
hiberlab.width_request = 730
hiberbuf = icon_theme.load_icon("xfsm-hibernate", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK)
hiberimg = Gtk::Image.new(hiberbuf)
hiberimg.set_alignment(0,0.5)

if is_hibernated == true
        table.attach(hiberlab, 1, 2, 2, 3, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 15)
        table.attach(hiberimg, 0, 1, 2, 3, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 15)
end

# Label memory

memlab = Gtk::Label.new
memlab.set_markup("<b>" + tl.get_translation("badmem_head") +  "</b>\n\n" + tl.get_translation("badmem_text"))
memlab.wrap = true
memlab.width_request = 730

membuf = icon_theme.load_icon("computer-fail", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK)
memimg = Gtk::Image.new(membuf)
memimg.set_alignment(0,0.5)

if badmem == true
        table.attach(memlab, 1, 2, 3, 4, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 15)
        table.attach(memimg, 0, 1, 3, 4, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 15)
end

# Label squashfs

squashlab = Gtk::Label.new
squashlab.set_markup("<b>" + tl.get_translation("badsquash_head") +  "</b>\n\n" + tl.get_translation("badsquash_text"))
squashlab.wrap = true
squashlab.width_request = 730

squashbuf = icon_theme.load_icon("computer-fail", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK)
squashimg = Gtk::Image.new(squashbuf)
squashimg.set_alignment(0,0.5)

if squasherror == true
        table.attach(squashlab, 1, 2, 4, 5, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 15)
        table.attach(squashimg, 0, 1, 4, 5, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 15)
end

# Label SMART

smartlab = Gtk::Label.new
smartlab.set_markup("<b>" + tl.get_translation("smart_head") +  "</b>\n\n" + tl.get_translation("smart_text"))
smartlab.wrap = true
smartlab.width_request = 730

smartbuf = icon_theme.load_icon("drive-harddisk", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK)
smartimg = Gtk::Image.new(smartbuf)
smartimg.set_alignment(0,0.5)

if smartfail == true
        table.attach(smartlab, 1, 2, 5, 6, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 15)
        table.attach(smartimg, 0, 1, 5, 6, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 15)
end

# Label too hot

toohotlab = Gtk::Label.new
toohotlab.set_markup("<b>" + tl.get_translation("toohot_head") +  "</b>\n\n" + tl.get_translation("toohot_text"))
toohotlab.wrap = true
toohotlab.width_request = 730

toohotbuf = icon_theme.load_icon("computer-fail", 48, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK)
toohotimg = Gtk::Image.new(toohotbuf)
toohotimg.set_alignment(0,0.5)

if toohot == true
        table.attach(toohotlab, 1, 2, 6, 7, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 15)
        table.attach(toohotimg, 0, 1, 6, 7, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 15)
end

# Buttons

buttonbox = Gtk::HBox.new(true, 5)
continue = Gtk::Button.new(tl.get_translation("button_continue"))
shutdown = Gtk::Button.new(tl.get_translation("button_shutdown"))
continue.signal_connect('clicked') {
	Gtk.main_quit
}
shutdown.signal_connect('clicked') {
	system("poweroff")
}

buttonbox.pack_end_defaults(shutdown)
buttonbox.pack_end_defaults(continue)
table.attach(buttonbox, 0, 2, 7, 8, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 15)

# Show everything

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
window.set_title("Warnung")
window.window_position = Gtk::Window::POS_CENTER_ALWAYS
window.deletable = false
window.decorated = false
# window.width_request = 600
# window.height_request = 400
window.add table
window.show_all
# shutdown.grab_default
shutdown.grab_focus

Gtk.main
