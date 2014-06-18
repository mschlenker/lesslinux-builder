#!/usr/bin/ruby
# encoding: utf-8
require 'gtk2'
require 'uri'

def connect(host, domain, user, pw, quality)
	system("killall -9 xfreerdp")
	q = "-x m -a 16"
	q = "-x b -a 16" if quality > 0.0
	q = "-x l -a 32" if quality > 1.0
	q = "-x 180 -a 32" if quality > 2.0
	q = q + " -d '#{domain}'" unless domain.strip == ""
	xfr = "xfreerdp --ignore-certificate -f " + q + " -u '#{user}' -p '#{pw}' '#{host}' "
	# puts xfr
	system(xfr + " &")
end

default_host = URI.decode(ARGV[0])
default_user = URI.decode(ARGV[1])
default_domain = URI.decode(ARGV[2])
default_quality = ARGV[3].to_f 

icon_theme = Gtk::IconTheme.default
window = Gtk::Window.new(Gtk::Window::TOPLEVEL)
window.set_title( "RDP Login" )
window.border_width = 10
window.signal_connect('delete_event') { Gtk.main_quit }
window.decorated = false
window.resizable = false
window.window_position = Gtk::Window::POS_CENTER_ALWAYS

table = Gtk::Table.new(7, 2)
header = Gtk::Label.new
header.set_markup("<b>Remote Desktop Login</b>")
table.attach(header, 0, 2, 0, 1, nil, nil, 3, 2) 
table.attach(Gtk::Label.new("Host:"), 0, 1, 1, 2, nil, nil, 3, 2) 
table.attach(Gtk::Label.new("Domain:"), 0, 1, 2, 3, nil, nil, 3, 2) 
table.attach(Gtk::Label.new("User:"), 0, 1, 3, 4, nil, nil, 3, 2)
table.attach(Gtk::Label.new("Password:"), 0, 1, 4, 5, nil, nil, 3, 2)
table.attach(Gtk::Label.new("Quality:"), 0, 1, 5, 6, nil, nil, 3, 2)
input_host = Gtk::Entry.new
input_host.text = default_host
input_domain = Gtk::Entry.new
input_domain.text = default_domain
input_user = Gtk::Entry.new
input_user.text = default_user
input_pass = Gtk::Entry.new
input_pass.visibility = false
rcount = 1
[ input_host, input_domain, input_user, input_pass].each { |i| 
	i.width_request = 200
	table.attach(i, 1, 2, rcount, rcount + 1) 
	rcount += 1
}
qscale = Gtk::HScale.new(0.0, 3.0, 1.0)
qscale.width_request = 200
qscale.value = default_quality
qscale.draw_value = true
table.attach(qscale, 1, 2, rcount, rcount + 1) 
rcount += 1

sd = Gtk::Button.new
sd.tooltip_text = "Shutdown"
sd.image = Gtk::Image.new(icon_theme.load_icon("gtk-cancel", 24, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
go = Gtk::Button.new
go.tooltip_text = "Go"
go.image = Gtk::Image.new(icon_theme.load_icon("next", 24, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
# Three buttons: Firefox, Remmina, Shutdown
align = Gtk::Alignment.new(1.0, 0.0, 0.0, 0.0)
buttbox = Gtk::HBox.new(false, 5)
ff = Gtk::Button.new
ff.image = Gtk::Image.new(icon_theme.load_icon("firefox", 24, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
ff.tooltip_text = "Firefox"
buttbox.pack_start_defaults(ff)
# buttbox.pack_start_defaults(sd)
align.add buttbox
buttbox.pack_start_defaults(sd)
buttbox.pack_start_defaults(go)
table.attach(align, 1, 2, rcount, rcount + 1) 

go.signal_connect('clicked') { 
	pw = input_pass.text
	input_pass.text = ""
	while Gtk.events_pending?
		Gtk.main_iteration
	end
	connect(input_host.text, input_domain.text, input_user.text, pw, qscale.value)
}
input_pass.signal_connect('activate') {
	pw = input_pass.text
	input_pass.text = ""
	while Gtk.events_pending?
		Gtk.main_iteration
	end
	connect(input_host.text, input_domain.text, input_user.text, pw, qscale.value)
}

ff.signal_connect('clicked') { exec "firefox" }
sd.signal_connect('clicked') { exec "shutdown-wrapper.sh" }

window.add table 
window.show_all
input_pass.grab_focus unless default_host.to_s == ""
Gtk.main
