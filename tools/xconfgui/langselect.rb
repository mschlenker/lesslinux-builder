#!/usr/bin/ruby
# encoding: utf-8

require 'gtk2'
require 'MfsDiskDrive'

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?

# Now try to read the language from the registry
Dir.entries("/sys/block").each { |l|
	if l =~ /[a-z]$/ ||  l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/
		begin
			d =  MfsDiskDrive.new(l, true)
			if d.usb == false
				d.partitions.each{ |p|
					l, d = p.get_language
					lang = l[0..1] unless l.nil? 
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
	"de" => "Deutsch",
	"en" => "English",
	"fr" => "Français",
	"es" => "Español",
	"pl" => "Polski",
	"ru" => "Русский", 
	"it" => "Italiano",
	"nl" => "Nederlands"
}
@langorder = @languages.keys.sort 

@keymapdefaults = {
	"de" => "de",
	"en" => "us",
	"fr" => "fr",
	"es" => "es", 
	"pl" => "pl",
	"ru" => "ru",
	"it" => "it",
	"nl" => "nl"
}

@langlabels = {
	"en" => "Select your language",
	"de" => "Wählen Sie Ihre Sprache"
}

@kbdlabels = {
	"en" => "Select your keyboard",
	"de" => "Wählen Sie Ihre Tastatur"
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
	langlabel = Gtk::Label.new(@langlabels["en"])
end
ltab.attach(langlabel, 0, 1, 0, 1, Gtk::SHRINK, Gtk::SHRINK, 3, 3)
langcombo = Gtk::ComboBox.new
@langorder.each { |k|
	langcombo.append_text(@languages[k]) 
}
unless @langorder.index(lang).nil?
	langcombo.active = @langorder.index(lang)
else
	langcombo.active = @langorder.index("en")
end
ltab.attach(langcombo, 2, 3, 0, 1, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 3, 3)

if @kbdlabels.has_key?(lang)
	kbdlabel = Gtk::Label.new(@kbdlabels[lang])
else
	kbdlabel = Gtk::Label.new(@kbdlabels["en"])
end
ltab.attach(kbdlabel, 0, 1, 1, 2, Gtk::SHRINK, Gtk::SHRINK,  3, 3)
kbdcombo = Gtk::ComboBox.new
@langorder.each { |k|
	kbdcombo.append_text(@languages[k]) 
}
unless @langorder.index(lang).nil?
	kbdcombo.active = @langorder.index(lang)
else
	kbdcombo.active = @langorder.index("en")
end
ltab.attach(kbdcombo, 2, 3, 1, 2, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 3, 3)
okbutton = Gtk::Button.new(Gtk::Stock::OK)  
ltab.attach(okbutton, 2, 3, 2, 3, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 3, 3)

# Callbacks

langcombo.signal_connect("changed") { |x|
	begin
		langlabel.text = @langlabels[@langorder[langcombo.active]] 
		kbdlabel.text = @kbdlabels[@langorder[langcombo.active]] 
	rescue
		langlabel.text = @langlabels["en"] 
		kbdlabel.text = @kbdlabels["en"] 
	end
	kbdcombo.active = langcombo.active
}

okbutton.signal_connect("clicked") {
	Gtk.main_quit
}

window.add ltab
okbutton.grab_default
okbutton.grab_focus
window.show_all
Gtk.main
