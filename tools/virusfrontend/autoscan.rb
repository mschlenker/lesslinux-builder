#!/usr/bin/ruby
# encoding: utf-8

require 'glib2'
require 'gtk2'
require 'tempfile' 
require 'vte'

def check_log
	virus = false 
	File.open(@logfile.path).each { |line|
		virus = true if line.strip =~ /Infected.*\s1/ 
	}
	return virus 
end

def showinfo 
	dialog = Gtk::Dialog.new(
		"Schadsoftware gefunden!",
		$mainwindow,
		Gtk::Dialog::MODAL,
		[ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
	)
	dialog.default_response = Gtk::Dialog::RESPONSE_OK
	dialog.has_separator = false
	label = Gtk::Label.new
	label.set_markup("In der Datei #{@basename} wurde Schadsoftware gefunden, sie wurde deshalb gelöscht.")
	label.wrap = true
	label.width_request = 350
	expander = Gtk::Expander.new("_Details anzeigen", true)
	txarea = Gtk::TextView.new
	txarea.wrap_mode = Gtk::TextTag::WRAP_WORD
	disctext = File.new(@logfile.path).read
	txarea.buffer.text = disctext 
	txarea.width_request = 400
	txarea.height_request = 320
	font = Pango::FontDescription.new("Monospace 10")
	txarea.modify_font(font)
	expander.add txarea
	image = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)
	vbox = Gtk::VBox.new(false, 5)
	hbox = Gtk::HBox.new(false, 5)
	hbox.border_width = 10
	hbox.pack_start_defaults(image)
	hbox.pack_start_defaults(label)
	vbox.pack_start_defaults(hbox)
	vbox.pack_start_defaults(expander)
	dialog.vbox.add(vbox)
	dialog.show_all
	dialog.run { |resp|
		dialog.destroy
		return true
	}
end

@logfile = Tempfile.new("avira.")
@logfile.close 
@running = true
@basename = File.basename(ARGV[0])

window = Gtk::Window.new
pgbar = Gtk::ProgressBar.new
pgbar.width_request = 450
pgbar.height_request = 32
pgbar.text = "Untersuche Datei auf Schadsoftware: #{@basename}"

window.add pgbar
window.window_position = Gtk::Window::POS_CENTER_ALWAYS
window.deletable = false
window.decorated = false
window.allow_grow = false
window.allow_shrink = false

vte = Vte::Terminal.new
vte.signal_connect("child_exited") { @running = false }

window.signal_connect("delete_event") {
        puts "delete event occurred"
        false
}

window.signal_connect("destroy") {
        puts "destroy event occurred"
        Gtk.main_quit
}

# VTE process finished, swiftly analyze log... 
# Show window when file was infected and deleted
# Exit gracefully, if everything was OK

window.signal_connect("show") {
	# Befehl in VTE starten
	vte.fork_command("/AntiVir/scancl", [ "/AntiVir/scancl", "--defaultaction=delete", "--quarantine=/tmp", "--log=#{@logfile.path}",  ARGV[0]] )
	while @running == true
		pgbar.pulse 
                while (Gtk.events_pending?)
	               Gtk.main_iteration
                end
	       sleep 0.1
	end
	if check_log == true
		showinfo
		puts "Virus found!"
	else	
		puts "Everything OK!"
	end
	@logfile.unlink 
        exit 0
}





# window.width_request = 400 
# window.height_request = 100

window.show_all
Gtk.main
