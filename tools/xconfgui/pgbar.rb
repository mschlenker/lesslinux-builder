#!/usr/bin/ruby

require 'glib2'
require 'gtk2'

window = Gtk::Window.new
pgbar = Gtk::ProgressBar.new
pgbar.width_request = 400
pgbar.height_request = 40

window.signal_connect("delete_event") {
        puts "delete event occurred"
        false
}

window.signal_connect("destroy") {
        puts "destroy event occurred"
        Gtk.main_quit
}

window.signal_connect("show") {
        0.upto(50) { |n|
                pgbar.fraction = n.to_f / 50.0
                while (Gtk.events_pending?)
                        Gtk.main_iteration
                end
                sleep 0.01
        }
        system("touch /var/run/lesslinux/display_opened_successfully")
        exit 0
}

window.add pgbar
window.window_position = Gtk::Window::POS_CENTER_ALWAYS
window.deletable = false
window.decorated = false
window.allow_grow = false
window.allow_shrink = false

# window.width_request = 400 
# window.height_request = 100

window.show_all
Gtk.main
