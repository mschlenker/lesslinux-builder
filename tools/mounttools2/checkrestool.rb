#!/usr/bin/ruby
# encoding: utf-8

IO.popen("xrandr") { |line|
	while line.gets
		l = $_ 
		if l =~ /connected\s([0-9]+)x([0-9]+)\+/
			mw = 0
			mh = 0
			w = $1.to_i
			h = $2.to_i 
			puts "#{w} x #{h}" 
			if l =~ /([0-9]+)mm\sx\s([0-9]+)mm/ 
				mw = $1.to_i
				mh = $2.to_i
				puts "#{mw} x #{mh}" 
			end
			exit 1 if ( mw < 1 || mh < 1 )
			puts ( mw.to_f / w.to_f ).to_s 
			exit 1 if ( mw.to_f / w.to_f < 0.156 ) 
		end
	end
}

exit 0

