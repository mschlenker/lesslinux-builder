#!/usr/bin/ruby
# Wait for an arbitary service that writes his "done file" 
#
# /var/log/lesslinux/bootlog/service.done
#
# Title and 

require 'glib2'
require 'gtk2'

@service = ARGV[0].strip 
@exec = ARGV[2].to_s.strip 
exit 0 if File.exists?("/var/log/lesslinux/bootlog/#{@service}.done")

window = Gtk::Window.new
pgbar = Gtk::ProgressBar.new
pgbar.width_request = 400
pgbar.height_request = 32

window.signal_connect("delete_event") {
        puts "delete event occurred"
        false
}

window.signal_connect("destroy") {
        puts "destroy event occurred"
        Gtk.main_quit
}

window.signal_connect("show") {
        while File.exists?("/var/log/lesslinux/bootlog/#{@service}.done") == false
                pgbar.pulse
                while (Gtk.events_pending?)
                        Gtk.main_iteration
                end
                sleep 0.1
        end
	exec(@exec) unless @exec == ""
        exit 0
}

window.add pgbar
window.window_position = Gtk::Window::POS_CENTER_ALWAYS
window.title = "Waiting for service: #{@service}"
window.title = ARGV[1].strip unless ARGV[1].nil? 
window.deletable = false
window.decorated = true
window.allow_grow = false
window.allow_shrink = false

# window.width_request = 400 
# window.height_request = 100

window.show_all
Gtk.main
