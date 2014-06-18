#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'

#============================================================================
# localization
#============================================================================

LANGUAGE = ENV['LANGUAGE'][0..1]
LOCSTRINGS = {
	"de" => {
		"pw_title" => "Passwort",
		"pw_password" => "Passwort:",
		"pw_desc" => "Diese Aktion erfordert ein Passwort!"
	},
	"en" => {
		"pw_title" => "Password",
		"pw_password" => "Password:",
		"pw_desc" => "This action requires a password!"
	},
	"ru" => {
		"pw_title" => "Пароль",
                "pw_password" => "Пароль:",
                "pw_desc" => "Для выполнения этого действия требуется пароль!"
	},
	"es" => {
                "pw_title" => "Contraseña",
                "pw_password" => "Contraseña:",
                "pw_desc" => "Esta acción requiere una contraseña"
        },
	"pl" => {
                "pw_title" => "Hasło",
                "pw_password" => "Hasło:",
                "pw_desc" => "Ta czynność wymaga podania hasła!"
	}
}

def extract_lang_string(string_id)
	lang = "en"
	lang = LANGUAGE unless LANGUAGE.nil?
	message_string = "message not found: " + string_id
	begin
		message_string = LOCSTRINGS['en'][string_id]
	rescue
	end
	begin
		message_string = LOCSTRINGS[lang][string_id]
	rescue
	end
	return message_string #.gsub('%BRANDLONG%', get_brandlong)
end

#============================================================================
# core logic
#============================================================================

window = Gtk::Window.new(Gtk::Window::TOPLEVEL)
window.set_title( extract_lang_string("pw_title") )
window.border_width = 10
window.signal_connect('delete_event') { Gtk.main_quit }

question  = Gtk::Label.new( extract_lang_string("pw_desc") )
entry_label = Gtk::Label.new( extract_lang_string("pw_password") )

pass = Gtk::Entry.new
pass.visibility = false
pass.signal_connect('activate') {
	puts pass.text
	Gtk.main_quit
}

# The following property takes integer value not string character
# pass.invisible_char = 42           ### for instance 42=asterisk

hbox = Gtk::HBox.new(false, 5)
hbox.pack_start_defaults(entry_label)
hbox.pack_start_defaults(pass)
vbox = Gtk::VBox.new(false, 5)
vbox.pack_start_defaults(question)
vbox.pack_start_defaults(hbox)

window.add(vbox)
window.show_all
Gtk.main
