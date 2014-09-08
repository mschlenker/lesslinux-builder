#!/usr/bin/ruby
# encoding: utf-8

require "rexml/document"
require 'glib2'
require 'gtk2'
# require 'MfsDiskDrive.rb'
# require 'MfsSinglePartition.rb'
require 'MmmmDriveList.rb'

#============================================================================
# define some global variables we might use later
#============================================================================

#============================================================================
# localization
#============================================================================

LANGUAGE = ENV['LANGUAGE'][0..1]
LOCSTRINGS = {
	"de" => {
		"pw_title" => "Passwort",
		"pw_password" => "Passwort:",
		"pw_desc" => "Diese Aktion erfordert ein Passwort!",
		"pan_usbdrive" => "USB-Laufwerk",
		"pan_sysdrive" => "Systemlaufwerk",
		"pan_stick" => "USB-Stick",
		"pan_part" => "Partition",
		"pan_optical" => "CD/DVD",
		"pan_layout" => "%DRIVE% %ACTION%",
		"pan_mount" => "einbinden",
		"pan_umount" => "lösen",
		"pan_mount_error" => "Zugriff fehlgeschlagen oder abgebrochen.",
		"pan_umount_error" => "Lösen der Laufwerkseinbindung fehlgeschlagen. Bitte stellen Sie sicher, dass kein weiterer Prozess auf das Laufwerk zugreift.",
		"pan_show" => "Inhalt anzeigen",
		"pan_writable" => "schreibbar?",
		"win_title" => "Laufwerke"
	},
	"en" => {
		"pw_title" => "Password",
		"pw_password" => "Password:",
		"pw_desc" => "This action requires a password!",
		"pan_usbdrive" => "USB drive",
		"pan_sysdrive" => "System drive",
		"pan_stick" => "USB stick",
		"pan_part" => "partition",
		"pan_optical" => "CD/DVD",
		"pan_layout" => "%ACTION% %DRIVE%",
		"pan_mount" => "Mount",
		"pan_umount" => "Unmount",
		"pan_mount_error" => "Mount failed or cancelled.",
		"pan_umount_error" => "Unmounting of the selected drive failed. Please make sure that no other process currently accesses the drive.",
		"pan_show" => "Show content",
		"pan_writable" => "writable?",
		"win_title" => "Disks"
	},
	"ru" => {
                "pw_title" => "Пароль",
                "pw_password" => "Пароль:",
                "pw_desc" => "Для выполнения этого действия требуется пароль!",
                "pan_usbdrive" => "USB-накопитель",
                "pan_sysdrive" => "Системный диск",
                "pan_stick" => "Флэш-накопитель",
                "pan_part" => "раздел",
                "pan_optical" => "CD/DVD",
                "pan_layout" => "%ACTION% %DRIVE%",
                "pan_mount" => "Монтировать",
                "pan_umount" => "Демонтировать",
                "pan_mount_error" => "Ошибка при монтировании или отмена.",
                "pan_umount_error" => "Ошибка при демонтировании выбранного устройства. Пожалуйста, убедитесь, что устройство не используется другими программами.",
                "pan_show" => "Показать содержимое",
                "pan_writable" => "перезаписываемый?",
                "win_title" => "Диски"
        },
	"es" => {
                "pw_title" => "Contraseña",
                "pw_password" => "Contraseña:",
                "pw_desc" => "Esta acción requiere una contraseña",
                "pan_usbdrive" => "Disco USB",
                "pan_sysdrive" => "Disco de sistema",
                "pan_stick" => "Memoria USB",
                "pan_part" => "partición",
                "pan_optical" => "CD/DVD",
                "pan_layout" => "%ACTION% %DRIVE%",
                "pan_mount" => "Montar",
                "pan_umount" => "Desmontar",
                "pan_mount_error" => "Montaje fallido o cancelado.",
                "pan_umount_error" => "Fallo en el desmontaje del disco seleccionado. Por favor, asegúrate de que no hay otro proceso en marcha accediendo al disco.",
                "pan_show" => "Mostrar contenido",
                "pan_writable" => "¿escribible?",
                "win_title" => "Discos"
        },
	"pl" => {
                "pw_title" => "Hasło",
                "pw_password" => "Hasło:",
                "pw_desc" => "Ta czynność wymaga podania hasła!",
                "pan_usbdrive" => "Dysk USB",
                "pan_sysdrive" => "Dysk systemowy",
                "pan_stick" => "Nośnik USB",
                "pan_part" => "partycja",
                "pan_optical" => "CD/DVD",
                "pan_layout" => "%ACTION% %DRIVE%",
                "pan_mount" => "Montuj",
                "pan_umount" => "Odmontuj",
                "pan_mount_error" => "Montowanie nie powiodło się lub zostało anulowane.",
                "pan_umount_error" => "Odmontowywanie nie powiodło się. Upewnij się, że żaden proces nie korzysta z wybranego napędu.",
                "pan_show" => "Pokaż zawartość",
                "pan_writable" => "dozwolony zapis?",
                "win_title" => "Dyski"
        }
}



xmldrives = ` sudo xmldrivelist.sh ` 
# xmldrives = ` ruby -I. xmldrivelist.rb ` 
d = MmmmDriveList.new(REXML::Document.new(xmldrives), LOCSTRINGS[LANGUAGE])
window = Gtk::Window.new(Gtk::Window::TOPLEVEL)
window.set_title("Disks")
window.border_width = 10
window.set_size_request(600, 400)
scroll_pane = Gtk::ScrolledWindow.new
scroll_pane.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
scroll_pane.add_with_viewport(d.outer_vbox)
# window.add d.outer_vbox
window.add scroll_pane
window.signal_connect('delete_event') { Gtk.main_quit  }
window.show_all
Gtk.main
