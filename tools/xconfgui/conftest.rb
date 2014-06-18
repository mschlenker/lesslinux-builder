#!/usr/bin/ruby
# encoding: utf-8

require 'glib2' 
require 'gtk2'
require 'timeout'

LANGUAGE = ENV['LANGUAGE'][0..1]
LOCSTRINGS = {
	"de" => {
		"label" => "Falls Sie mit dieser Bildschirmauflösung starten wollen, klicken Sie bitte \"Anwenden\". Wenn Bildschirmauflösung oder Schriftgröße nicht passen, klicken Sie \"Abbrechen\" und wählen Sie andere Werte. Dieses Fenster wird nach 10 Sekunden geschlossen."
	},
	"en" => {
		"label" => "If the resolution is correct, please press \"Accept\", otherwise click \"Cancel\" and choose different settings. This window will be closed after 10 seconds."
	},
	"ru" => {
                "label" => "Если разрешение правильное, нажмите \"Принять\", в противном случае нажмите \"Отмена\" и измените настройки. Это окно будет закрыто через 10 секунд."
        },
	 "es" => {
                "label" => "Si la resolución es correcta, por favor presiona \"Aceptar\", si no presiona \"Cancelar\" y elige otros ajustes. Esta ventana se cerrará pasados 10 segundos."
        },
	 "pl" => {
                "label" => "Jeśli rozdzielczość jest odpowiednia, wciśnij \"Akceptuj\"; w innym wypadku wybierz \"Anuluj\" i zmień ustawienia. To okno zniknie za 10 sekund."
        }
}

# FIXME: extract common funtions for localization.

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
	return message_string
end

window = Gtk::Window.new("Monitortest")
window.signal_connect("destroy") { Gtk.main_quit }

label = Gtk::Label.new(extract_lang_string("label"))
label.wrap = true

layout_box = Gtk::VBox.new(false, 2)
button_box = Gtk::HBox.new(true, 2)
apply = Gtk::Button.new(Gtk::Stock::APPLY)
cancel = Gtk::Button.new(Gtk::Stock::CANCEL)

apply.signal_connect("clicked") {
	system("cp /var/run/lesslinux/xorg_vars.test /var/run/lesslinux/xorg_vars")
	Gtk.main_quit
}

cancel.signal_connect("clicked") { Gtk.main_quit }

button_box.pack_start(cancel, false, false,2)
button_box.pack_start(apply, false, false,2)

layout_box.pack_start(label, false, false, 2)
layout_box.pack_start(Gtk::HSeparator.new)
layout_box.pack_start(button_box, false, false, 2)
window.border_width = 10
window.add(layout_box)
window.allow_grow = false
window.allow_shrink = false
window.modal = true
window.show_all

Gtk.timeout_add(10000) {Gtk.main_quit}
Gtk.main
