#!/usr/bin/ruby
# encoding: utf-8

mw = 0
mh = 0
w = 0
h = 0

IO.popen("xrandr") { |line|
	while line.gets
		l = $_ 
		if l =~ /Failed to get size of gamma/i
			# VESA mode 
			exit 0 
		elsif l =~ /current\s([0-9]+)\sx\s([0-9]+)/
			w = $1.to_i
			h = $2.to_i 
			puts "#{w} x #{h}" 
		elsif l =~ /([0-9]+)mm\sx\s([0-9]+)mm/ 
			mw = $1.to_i
			mh = $2.to_i
			puts "#{mw} x #{mh}" 
		end
	end
}

exit 1 if ( mw * mh < 1 && w > 1366 )
exit 0 if ( mw * mh < 1 ) 
puts ( mw.to_f / w.to_f ).to_s 
exit 1 if ( mw.to_f / w.to_f < 0.156 ) 
exit 0
