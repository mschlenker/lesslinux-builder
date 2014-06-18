#!/usr/bin/ruby
# encoding: utf-8
require 'gtk2'
require "rexml/document"

@ether_addr = Array.new
@inet_addr = Array.new
@execs = Array.new

# Parse the XML file supplied 

def get_ether
	IO.popen("ip -f link addr") { |io|
		while line = io.gets
				@ether_addr.push line.strip.split[1].downcase if line.strip =~ /^link\/ether/  
		end
	}
	@ether_addr.uniq!
end

def get_inet
	IO.popen("ip -f inet addr") { |io|
		while line = io.gets
				@inet_addr.push line.strip.split[1].split("/")[0] if line.strip =~ /^inet/  
		end
	}
	@inet_addr.uniq!
end

def fill_combo(combo, button, pwinp)
	# puts ARGV[0].to_s 
	# execs = Array.new
	ccount = 0
	default = 0
	begin
		xcfg = REXML::Document.new( File.new( ARGV[0] ) )
		xcfg.elements.each("/chooser/connect") { |element| 
			# puts element.attributes["nicename"]
			combo.append_text element.attributes["nicename"]
			element.elements.each("default") { |d|
				default = ccount if @ether_addr.include?(d.attributes["ether"].to_s.downcase.to_s)
				default = ccount if @inet_addr.include?(d.attributes["inet"].to_s)
			}
			extraparams = Array.new
			element.elements.each("param") { |p|
				extraparams.push p.text.to_s 
			}
			extraparams.push("-d " + element.attributes["domain"].to_s) unless element.attributes["domain"].to_s.strip == ""
			xs = extraparams.join(" ") + " --ignore-certificate -f -u \"" + element.attributes["user"].to_s + "\" \"" + element.attributes["host"] + "\"" 
			puts xs
			@execs.push xs
			ccount += 1
		}
	rescue
		ccount = 0
	end
	if ccount < 1 
		combo.append_text("No connections specified")
		combo.active = 0
		combo.sensitive = false
		button.sensitive = false
		pwinp.sensitive = false
	end
	combo.active = default
	# return execs
end

def connect(num, password)
	system("killall -9 xfreerdp")
	pw = password.text
	password.text = ""
	while Gtk.events_pending?
		Gtk.main_iteration
	end
	params = " -p '#{pw}' "
	# puts( "xfreerdp " + params + @execs[num] + " &")
	system( "xfreerdp " + params + @execs[num] + " &")
end

# 

icon_theme = Gtk::IconTheme.default

window = Gtk::Window.new(Gtk::Window::TOPLEVEL)
window.set_title( "Chooser" )
window.border_width = 10
window.signal_connect('delete_event') { Gtk.main_quit }
window.decorated = false
window.resizable = false
window.window_position = Gtk::Window::POS_CENTER_ALWAYS

# ComboBox for hosts and Go button

dropdbox = Gtk::HBox.new(false, 5)
combo = Gtk::ComboBox.new
combo.width_request = 350
dropdbox.pack_start_defaults(combo)
go = Gtk::Button.new
go.tooltip_text = "Go"
go.image = Gtk::Image.new(icon_theme.load_icon("next", 24, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
# dropdbox.pack_start_defaults(go)

# Input box for password

pwbox = Gtk::HBox.new(false, 5)
pwinp = Gtk::Entry.new
pwinp.visibility = false
pwinp.width_request = 350
pwinp.height_request = 24
pwbox.pack_start_defaults(pwinp)
sd = Gtk::Button.new
sd.tooltip_text = "Shutdown"
sd.image = Gtk::Image.new(icon_theme.load_icon("gtk-cancel", 24, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
# pwbox.pack_start_defaults(sd)

# Three buttons: Firefox, Remmina, Shutdown

align = Gtk::Alignment.new(1.0, 0.0, 0.0, 0.0)
buttbox = Gtk::HBox.new(false, 5)
wi = Gtk::Button.new
wi.image = Gtk::Image.new(icon_theme.load_icon("preferences-system-network", 24, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
wi.tooltip_text = "WICD Network Manager"
# buttbox.pack_start_defaults(wi)
ff = Gtk::Button.new
ff.image = Gtk::Image.new(icon_theme.load_icon("firefox", 24, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
ff.tooltip_text = "Firefox"
buttbox.pack_start_defaults(ff)
rm = Gtk::Button.new
rm.image = Gtk::Image.new(icon_theme.load_icon("remmina", 24, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
rm.tooltip_text = "Remmina"
# buttbox.pack_start_defaults(rm)
# buttbox.pack_start_defaults(sd)
align.add buttbox

buttbox.pack_start_defaults(sd)
buttbox.pack_start_defaults(go)

# Now combine everything

vbox = Gtk::VBox.new(false, 5)
vbox.pack_start_defaults(dropdbox)
vbox.pack_start_defaults(pwbox)
vbox.pack_start_defaults(align)

# Wire actions

get_ether
get_inet
puts get_ether.join(" ")
puts get_inet.join(" ")
fill_combo(combo, go, pwinp)

go.signal_connect('clicked') { 
	connect(combo.active, pwinp)
}
pwinp.signal_connect('activate') {
	connect(combo.active, pwinp)
}
wi.signal_connect('clicked') { exec "wicd-client --no-tray" } 
ff.signal_connect('clicked') { exec "firefox" }
rm.signal_connect('clicked') { exec "remmina" }
sd.signal_connect('clicked') { exec "shutdown-wrapper.sh" }

pwinp.grab_focus
ff.grab_focus if @execs.size < 1 

# Show window

window.add vbox
window.show_all
Gtk.main