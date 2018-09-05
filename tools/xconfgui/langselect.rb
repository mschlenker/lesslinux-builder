#!/usr/bin/ruby
# encoding: utf-8

require 'gtk2'
require 'MfsDiskDrive'
require 'fileutils'

lang = ENV['LANGUAGE'][0..4]
lang = ENV['LANG'][0..4] if lang.nil?
lang = "en_GB" if lang.nil?

# Now try to read the language from the registry
Dir.entries("/sys/block").each { |l|
	if l =~ /[a-z]$/ ||  l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/
		begin
			d =  MfsDiskDrive.new(l, true)
			if d.usb == false
				d.partitions.each{ |p|
					l, d = p.get_language
					lang = l[0..4].gsub("-", "_") unless l.nil? 
				}
			end	
			$stderr.puts "Got language from Registry: #{lang}"
		rescue 
			$stderr.puts "Failed adding: #{l}"
		end
	end
}

@kbdchanged = false

@languages = {
	"de_DE" => "Deutsch",
	"en_GB" => "English",
	"fr_FR" => "Français",
	"es_ES" => "Español",
	"pl_PL" => "Polski",
	"ru_RU" => "Русский", 
	"it_IT" => "Italiano",
	"nl_NL" => "Nederlands",
	"da_DK" => "Dansk",
	"pt_PT" => "Português",
	"lt_LT" => "Lietuvių",
	"lv_LV" => "Latviešu",
	"et_ET" => "Eesti",
	"sk_SK" => "Slovenčina",
	"sl_SL" => "Slovenščina",
	"sv_SE" => "Svenska",
	"bg_BG" => "Български",
	"hr_HR" => "Hrvatski",
	"nb_NO" => "Norsk Bokmål",
	"ro_RO" => "Română",
	"sr_RS" => "Srpski",
	"tr_TR" => "Türkçe",
	"cs_CZ" => "Čeština",
	"hu_HU" => "Magyar",
	"fi_FI" => "Suomi",
	"el_GR" => "Ελληνικά"
}
@langorder = @languages.keys.sort 

@keymapdefaults = { }

@langlabels = {
	"en_GB" => "Select your language",
	"de_DE" => "Wählen Sie Ihre Sprache"
}

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
window.set_title("Select your language")
window.window_position = Gtk::Window::POS_CENTER_ALWAYS

ltab = Gtk::Table.new(5, 3)
if @langlabels.has_key?(lang)
	langlabel = Gtk::Label.new(@langlabels[lang])
else 
	match_found = false
	@langorder.each { |l|
		if l[0..1] == lang[0..1]
			langlabel = Gtk::Label.new(@langlabels[l])
			match_found = true
		end
	}
	langlabel = Gtk::Label.new(@langlabels["en_GB"]) if match_found == false
end
ltab.attach(langlabel, 0, 1, 0, 1, Gtk::SHRINK, Gtk::SHRINK, 3, 3)
langcombo = Gtk::ComboBox.new
@langorder.each { |k|
	langcombo.append_text(@languages[k]) 
}
unless @langorder.index(lang).nil?
	langcombo.active = @langorder.index(lang)
else
	match_found = false
	@langorder.each { |l|
		if l[0..1] == lang[0..1]
			langcombo.active = @langorder.index(l)
			match_found = true
		end
	}
	langcombo.active = @langorder.index("en_GB")  if match_found == false
end
ltab.attach(langcombo, 2, 3, 0, 1, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 3, 3)

okbutton = Gtk::Button.new(Gtk::Stock::OK)  
ltab.attach(okbutton, 2, 3, 2, 3, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 3, 3)

# Callbacks

langcombo.signal_connect("changed") { |x|
	begin
		langlabel.text = @langlabels[@langorder[langcombo.active]] 
	rescue
		langlabel.text = @langlabels["en_GB"] 
	end
}

okbutton.signal_connect("clicked") {
	f = File.new("/etc/lesslinux/cmdline", "a+")
	lshort = @langorder[langcombo.active].split("_")[0]
	f.write(" xlocale=#{@langorder[langcombo.active]}.UTF-8 lang=#{lshort} ") 
	f.close
	if system("mountpoint /lesslinux/boot")
		f = File.new("/lesslinux/boot/cmdline", "a+")
		f.write(" xlocale=#{@langorder[langcombo.active]}.UTF-8 nolangsel=1 lang=#{lshort} ") 
		f.close
	end
	Gtk.main_quit
}

window.add ltab
okbutton.grab_default
okbutton.grab_focus
window.show_all
Gtk.main
