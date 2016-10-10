#!/usr/bin/ruby
# encoding: utf-8

require 'gtk2'
# require 'vte'

labels = [
"<b>Datensicherung</b>\nSchadsoftware oder fehlgeschlagene Updates haben Windows unbrauchbar gemacht? Starten Sie eine Datensicherung auf Dateisystemebene. Ziellaufwerke können auch Cloud und NAS sein. Zugriff ist auch auf Schattenkopien möglich.",
"<b>Festplatte klonen</b>\nEine Festplatte weist Beschädigungen auf? Klonen Sie die defekte Platte auf eine neue gleich große oder größere bevor Datenverluste wertvolle Dateien betreffen. ",
"<b>Notfall-Image erstellen</b>\nEine Festplatte weist Beschädigungen auf, aber es ist keine neue Festplatte zur Hand? Erstellen Sie ein Notfall-Image, das Sie später auf eine neue Platte kopieren oder für eine Datenrettung nutzen können.",
"<b>Datenrettung auf Blockebene</b>\nRetten Sie mit QPhotoRec auch Daten von Festplatten, USB-Sticks oder SD-Karten, deren Dateisysteme beschädigt sind.",
"<b>Festplatten-Gesundheitscheck</b>\nLesen Sie die SMART-Werte Ihrer Festplatten und SSDs aus und erkennen Sie so Laufwerke, denen Schäden drohen.",
"<b>Virenscan</b>\nInstallieren Sie den Virenscanner AVG Free und führen Sie mit diesem eine Suche nach Schadsoftware durch"
]

commands = [ 
	"sudo /usr/bin/vshadowgui.sh & sudo /usr/bin/mountnet.sh & mmmmng.sh",
	"sudo clonedisk.sh",
	"sudo /usr/bin/ddrescueimage.sh",
	"sudo /usr/bin/qphotorec",
	"sudo /usr/bin/gsmartcontrol",
	"sudo /usr/share/lesslinux/avgfree/avg-wrapper.sh"
]

icons = [ 
	"/usr/share/icons/Faenza/devices/48/drive-harddisk-usb.png",
	"/usr/share/icons/Faenza/devices/48/drive-harddisk-system.png",
	"/usr/share/icons/Faenza/devices/48/drive-harddisk-system.png",
	"/usr/share/icons/Faenza/devices/48/camera.png",
	"/usr/share/icons/Faenza/apps/48/gnome-disks.png",
	"/usr/share/icons/Faenza/apps/48/comix.png"
]

window = Gtk::Window.new

bgimg = Gtk::Image.new("/etc/lesslinux/branding/bg_assistant.png")
# bgimg = Gtk::Image.new("/tmp/bg_assistant.png")
fixed = Gtk::Fixed.new
fixed.put(bgimg, 0, 0)
minimize = Gtk::EventBox.new.add(Gtk::Image.new("images/minimize.png"))
fixed.put(minimize, 968, 0)
minimize.signal_connect('button_release_event') {
	puts "Minimize"
	window.iconify
}

button_width = 418
button_height = 110
button_space = 10
buttons = Array.new
button_offset_x = 80
button_offset_y = 100
icon_size = 48 

0.upto(5) { |n|
	posx = ( n % 2 ) * button_width + button_offset_x + ( n % 2 ) *  ( 2 * button_space + icon_size )  
	posy = ( n / 2 ) * button_height + button_offset_y + ( n / 2 ) * button_space
	buttons[n] = Gtk::Button.new
	buttons[n].width_request = button_width
	buttons[n].height_request = button_height
	unless labels[n].nil?
		l = Gtk::Label.new
		l.width_request = button_width - 8
		l.wrap = true
		l.set_markup(labels[n])
		# box = Gtk::HBox.new
		# box.pack_start_defaults( Gtk::Image.new(icons[n]) ) 
		#box.pack_start_defaults l
		buttons[n].image = l # box
	end
	unless icons[n].nil?
		icon = Gtk::Image.new(icons[n]) 
		fixed.put(icon, posx - icon_size - button_space , posy + ( button_offset_y - icon_size ) / 2 )
	end
	buttons[n].signal_connect("clicked") {
		system(commands[n] + " &") 
	}
	fixed.put(buttons[n], posx, posy)
	
}


window.set_size_request(1000, 476)
window.border_width = 0
window.window_position = Gtk::Window::POS_CENTER_ALWAYS

window.deletable = false
window.decorated = false
window.allow_grow = false
window.allow_shrink = false
window.title = "RescueGUI"

window.add fixed

window.show_all 

Gtk.main
