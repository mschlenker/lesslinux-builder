#!/usr/bin/ruby

require 'optparse'
require 'MfsDiskDrive'
require 'MfsSinglePartition'

@drives = Array.new
@threads = Array.new
@blank = false
@failed = Array.new
@lang = "en"

opts = OptionParser.new 
opts.on('-b', '--blank' )  { |i| @blank = true }
opts.parse!

def get_sizes
	swapsize = 0
	blobsize = 0
	homecont_min = 0
	homecont_max = 0
	File.open("/proc/cmdline").each { |line|
		toks = line.strip.split
		toks.each { |t|
			puts t if t =~ /^homecont=/
			puts t if t =~ /^blobsize=/
			puts t if t =~ /^swapsize=/
			puts t if t =~ /^lang=/
			if t =~ /^lang=/
				@lang = t.split("=")[1] 
			end
		}
	}
end	

Dir.entries("/sys/block").each { |l|
	if l =~ /[a-z]$/ 
		begin
			d =  MfsDiskDrive.new(l, true)
			if d.system_drive?
				system("blockdev --setra 16384 /dev/#{d.device}")
			else
				@drives.push(d)  if ( d.usb == true && d.mounted == false )
			end
		rescue 
			$stderr.puts "Failed adding: #{l}"
		end
	end
}

if @drives.size < 1
	puts "ERROR: No suitable target found"
	exit 0
end

system("clear")
puts "===> Let the fun begin..."
puts "Target drives:"
@drives.each { |d|
	puts "  Found USB drive: #{d.device}, size: #{d.human_size}"
}
puts "Parameters read from the command line:"
get_sizes 
puts "Do you want to install on all target drives? [y|N]"
answer = $stdin.gets
exit 1 unless answer =~ /^y/i 

0.upto(@drives.size - 1) { |n|
	@threads[n] = Thread.new {
		if @blank == true
			"===> Wiping device #{@drives[n].device} with zeros\n"
			system("dd if=/dev/zero of=/device/#{@drives[n].device}") 
		end
		puts "===> Start installation on drive: #{@drives[n].device}\n"
		sleep (n+2) * 5
		@failed.push @drives[n].device unless system("bash dothedirtyjob.sh #{@drives[n].device} #{@lang}")
		# i = LessLinuxInstaller.new(@drives[n])
		# i.run_installation(nil, [0,0]) 
		puts "===> Finish installation on drive: #{@drives[n].device}\n"
	}
}
@threads.each { |t| t.join }

if @failed.size > 0
	puts "+++> Installation failed on devices: " + @failed.join("; ") 
else
	puts "===> All drives installed successfully!" 
end

