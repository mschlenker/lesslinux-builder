#!/usr/bin/ruby
# encoding: utf-8

require 'rexml/document'
require 'glib2'
require 'gtk2'
require 'vte'
require 'MfsTranslator.rb'
require 'optparse'

def retrieve_interfaces
	IO.popen("ip link") { |line|
		while line.gets
			if $_ =~ /^[0-9]/
				if $_ =~ /LOOPBACK/ 
					puts "Ignore loopback interface"
				else
					ltoks = $_.strip.split
					iface = ltoks[1].gsub(":", "")
					puts iface 
					if system("iw dev #{iface} info") 
						@wifidevices.push iface
						@wificombo.append_text iface 
					else
						@wireddevices.push iface
						@wiredcombo.append_text iface 
					end
				end
			end
		end
	}
	@wiredcombo.active = 0 if @wireddevices.size > 0
	@wificombo.active = 0 if @wifidevices.size > 0
end

def start_ap
	cffile = File.new("/etc/hostapd.conf.lesslinux", "w")
	iface = @wifidevices[@wificombo.active]
	eface = @wireddevices[@wiredcombo.active]
	cffile.write("interface=#{iface}\n")
	cffile.write("ssid=#{@essid.text}\nhw_mode=g\nchannel=11\n")
	if @passcheck.active?
		cffile.write("wpa=3\nwpa_passphrase=#{@passentry.text}\n")
		cffile.write("wpa_key_mgmt=WPA-PSK WPA-PSK-SHA256 WPA-EAP WPA-EAP-SHA256\n")
	end
	cffile.close
	system("/etc/rc.d/0590-wicd.sh stop") 
	system("/etc/rc.d/0589-connman.sh stop") 
	system("rfkill unblock all")
	system("dhcpcd -x")
	# Put down all interfaces:
	[ iface, eface ].each { |d| system("ip link set dev #{d} down") }
	# Start bridge
	if File.exists?("/usr/sbin/brctl") 
		system("brctl addbr bridge0")
		system("brctl addif bridge0 #{eface}")
		# Start hostapd
		system("hostapd /etc/hostapd.conf.lesslinux &")
		system("brctl addif bridge0 #{iface}")
		# And up again
		[ iface, eface, "bridge0" ].each { |d| system("ip link set dev #{d} up") }
	else
		system("ip link add name bridge0 type bridge")
		[ eface, "bridge0" ].each { |d| system("ip link set dev #{d} up") }
		system("ip link set #{eface} master bridge0")
		system("hostapd /etc/hostapd.conf.lesslinux &")
		sleep 2.0
		system("ip link set dev #{iface} up") 
		system("ip link set #{iface} master bridge0")
		# system("ip link set dev #{iface} up") 
	end
	# Start DHCPCD
	system("dhcpcd -z bridge0")
end

def stop_ap
	iface = @wifidevices[@wificombo.active]
	eface = @wireddevices[@wiredcombo.active]
	system("dhcpcd -x")
	sleep 2.0
	system("killall hostapd")
	sleep 1.0
	system("killall -9 hostapd")
	[ iface, eface, "bridge0" ].each { |d| 
		system("ip link set #{d} nomaster") 
		system("ip link set dev #{d} down")
	}
	system("iplink delete bridge0 type bridge")
	[ iface, eface ].each { |d| system("ip link set dev #{d} up") }
	system("/etc/rc.d/0589-connman.sh start") 
	system("/etc/rc.d/0590-wicd.sh start") 
end

lang = ENV['LANGUAGE'][0..1]
lang = ENV['LANG'][0..1] if lang.nil?
lang = "en" if lang.nil?
tlfile = "accesspoint.xml"
tlfile = "/usr/share/lesslinux/drivetools/accesspoint.xml" if File.exists?("/usr/share/lesslinux/drivetools/accesspoint.xml")
@tl = MfsTranslator.new(lang, tlfile)

# Arrays to store network interfaces
@wifidevices = Array.new
@wireddevices = Array.new
@ap_running = false

window = Gtk::Window.new
window.signal_connect("delete_event") {
        puts "delete event occurred"
        false
}

window.signal_connect("destroy") {
        puts "destroy event occurred"
        Gtk.main_quit
}

# What does this tool do?
infoframe = Gtk::Frame.new(@tl.get_translation("infoframe")) 
infolabel = Gtk::Label.new
infolabel.wrap = true
infolabel.set_markup(@tl.get_translation("infolabel")) 
infoframe.add infolabel

# Which interfaces to use?
ifaceframe = Gtk::Frame.new(@tl.get_translation("ifaceframe")) 
ifacebox = Gtk::VBox.new
ifacebox.pack_start_defaults(Gtk::Label.new(@tl.get_translation("wired_interface")))
@wiredcombo = Gtk::ComboBox.new
ifacebox.pack_start_defaults(@wiredcombo)
ifacebox.pack_start_defaults(Gtk::Label.new(@tl.get_translation("wifi_interface"))) 
@wificombo = Gtk::ComboBox.new
ifacebox.pack_start_defaults(@wificombo)
ifaceframe.add ifacebox

# Passframe
passframe = Gtk::Frame.new(@tl.get_translation("passframe")) 
passbox = Gtk::VBox.new
@essid = Gtk::Entry.new
@essid.text = "LessLinuxAP" 
passbox.pack_start_defaults(@essid)
@passcheck = Gtk::CheckButton.new(@tl.get_translation("passcheck"))
passbox.pack_start_defaults(@passcheck)
@passcheck.active = true 
@passentry = Gtk::Entry.new
@passentry.text = ` uuidgen`.strip[9, 19]
@passentry.set_width_request 390
passbox.pack_start_defaults(@passentry)
passframe.add passbox 

@passcheck.signal_connect("clicked") {
	if @passcheck.active?
		@passentry.sensitive = true
	else
		@passentry.sensitive = false
	end
}

go = Gtk::Button.new(@tl.get_translation("go"))
go.signal_connect("clicked") {
	if @ap_running == true
		stop_ap
		@ap_running = false
		go.label = @tl.get_translation("go")
		@passcheck.sensitive = true
		@passentry.sensitive = true if @passcheck.active? 
		@wiredcombo.sensitive = true
		@wificombo.sensitive = true
		@essid.sensitive = true 
		window.deletable = true
	else
		window.deletable = false 
		@passcheck.sensitive = false
		@passentry.sensitive = false  
		@wiredcombo.sensitive = false
		@wificombo.sensitive = false
		@essid.sensitive = false 
		start_ap
		@ap_running = true
		go.label = @tl.get_translation("stop")
	end
}

lvb = Gtk::VBox.new
lvb.pack_start_defaults(infoframe)
lvb.pack_start_defaults(ifaceframe)
lvb.pack_start_defaults(passframe)
lvb.pack_start_defaults(go)

window.border_width = 10
window.width_request = 400 
window.set_title("LessLinux access point")
window.window_position = Gtk::Window::POS_CENTER_ALWAYS
window.add lvb

retrieve_interfaces 
if @wifidevices.size < 1 || @wireddevices.size < 1
	go.sensitive = false 
end
window.show_all
Gtk.main
