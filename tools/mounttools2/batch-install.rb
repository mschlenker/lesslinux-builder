#!/usr/bin/ruby
# encoding: utf-8

require "LessLinuxInstaller"
require "optparse"

@drives = Array.new
@threads = Array.new
@home = [ 0, 0 ]

opts = OptionParser.new 
opts.on('-h', '--home', :REQUIRED )  { |i|
	if x =~ /\,/ 
		@home = i.split(",").map { |n| n.to_i }
	else
		@home = [ i.to_i, i.to_i ] 
	end
}
opts.parse!

Dir.entries("/sys/block").each { |l|
	if l =~ /[a-z]$/ 
		begin
			d =  MfsDiskDrive.new(l, true)
			if d.system_drive?
				system("blockdev --setra 16384 /dev/#{d.device}")
			else
				@drives.push(d)  if d.usb == true
			end
		rescue 
			$stderr.puts "Failed adding: #{l}"
		end
	end
}

if @drives.size < 1
	puts "No suitable target found"
	exit 0
end

0.upto(@drives.size - 1) { |n|
	@threads[n] = Thread.new {
		puts "Installing on drive: #{@drives[n].device}\n"
		sleep = (n+2) * 5
		system("sleep #{sleep}")
		i = LessLinuxInstaller.new(@drives[n])
		i.run_installation(nil, [0,0]) 
	}
}

@threads.each { |t| t.join }
