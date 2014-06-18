#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
require 'timeout'

LANGUAGE = ENV['LANGUAGE'][0..1]
LOCSTRINGS = {
	"de" => {
		"autodetect" => "Diese Bildschirmeinstellung wurde automatisch erkannt. Wollen Sie sie verwenden?\n\nDieses Fenster wird nach 30 Sekunden geschlossen.",
		"yes_perfect" => "Ja, die Einstellung ist perfekt",
		"no_change" => "Nein, ich möchte Anpassungen vornehmen",
		"no_flickers" => "Nein, das Bild flimmert oder ist verzerrt"
	
	},
	"en" => {
		"autodetect" => "This resolution was automatically detected. Do you want to use ist?\n\nThis window will be closed after 30 seconds.",
		"no_change" => "No, I want to adjust the settings",
		"yes_perfect" => "Yes, the setting is perfect",
		"no_flickers" => "No, the image flickers or is distorted"
	},
	"ru" => {
                "autodetect" => "Это разрешение было определено автоматически. Вы хотите использовать его?\n\nЭто окно будет закрыто через 30 секунд.",
                "no_change" => "Нет, я хочу регулировать настройки",
                "yes_perfect" => "Да, настройки правильные",
                "no_flickers" => "Нет, изображение дрожит или отсутствует"
        },
	"es" => {
                "autodetect" => "Esta resolución ha sido detectada automáticamente. ¿Quieres utilizarla?\n\nEsta ventana se cerrará pasados 30 segundos.",
                "no_change" => "No, quiero ajustar la configuración",
                "yes_perfect" => "Sí, los ajustes están perfectos",
                "no_flickers" => "No, la imagen parpadea o está distorsionada"
        },
	"pl" => {
                "autodetect" => "Ta rozdzielczość została wykryta automatycznie. Czy chcesz ją pozostawić?\n\nNiniejsze okno zniknie za 30 sekund.",
                "no_change" => "Nie, chcę ręcznie zmienić ustawienia",
                "yes_perfect" => "Tak, to dobre ustawienie",
                "no_flickers" => "Nie, obraz miga lub jest zniekształcony"
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
	return message_string
end

window = Gtk::Window.new("Monitortest")
window.signal_connect("destroy") { Gtk.main_quit }

label = Gtk::Label.new(extract_lang_string("autodetect"))
label.wrap = true

apply = Gtk::Button.new(extract_lang_string("yes_perfect"))
setlater = Gtk::Button.new(extract_lang_string("no_change"))
cancel = Gtk::Button.new(extract_lang_string("no_flickers"))

layout_box = Gtk::VBox.new(false, 2)

apply.signal_connect("clicked") {
	# system("echo 'driver=xorg' > /var/run/lesslinux/xorg_vars")
	system("touch /var/run/lesslinux/xconfgui_skip_monitor")
	system("touch /var/run/lesslinux/xconfgui_xorg")
	Gtk.main_quit
}

setlater.signal_connect("clicked") {
	system("touch /var/run/lesslinux/xconfgui_xorg")
	Gtk.main_quit
}

cancel.signal_connect("clicked") { Gtk.main_quit }

layout_box.pack_start(label, false, false, 2)
layout_box.pack_start(Gtk::HSeparator.new)
layout_box.pack_start(apply, false, false, 2)
layout_box.pack_start(setlater, false, false, 2)
layout_box.pack_start(cancel, false, false, 2)

window.border_width = 10
window.add(layout_box)
window.allow_grow = false
window.allow_shrink = false
window.modal = true
window.show_all

Gtk.timeout_add(35000) {Gtk.main_quit}
Gtk.main
