#!/usr/bin/ruby
# encoding: utf-8

require "rexml/document"
require 'MfsDiskDrive.rb'
require 'MfsSinglePartition.rb'

subcommand = ARGV[0]
drives = Array.new

unless (subcommand == "mount" || subcommand == "umount")
	exit 1
end

if ARGV.size < 2
	exit 1
end

Dir.entries("/sys/block").each { |l|
	drives.push(MfsDiskDrive.new(l, true)) if l =~ /[a-z]$/ 
}
Dir.entries("/sys/block").each { |l|
	drives.push(MfsDiskDrive.new(l, true)) if ( l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/ )
}
Dir.entries("/sys/block").each { |l|
	drives.push(MfsDiskDrive.new(l, true)) if l =~ /sr[0-9]$/ 
}

retval = 0
drives.each { |d|
	# puts d.device 
	d.partitions.each { |p|
		# puts p.device 
		if p.device == ARGV[1] && subcommand == "mount"
			if ARGV[2].to_s == "rw" 
				p.mount("rw", "/media/disk/" + p.device, 1000, 1000)
			else
				p.mount("ro", "/media/disk/" + p.device, 1000, 1000)
			end
			retval = 1 if p.mount_point.nil?			
		elsif p.device == ARGV[1] && subcommand == "umount"
			unless p.umount
				p.force_umount
			end
			retval = 1 unless p.mount_point.nil? 
		end
	}
	if (d.device == ARGV[1] && ARGV[1] =~ /^sr[0-9]$/ && d.partitions.size < 1)
		if subcommand == "mount"
			system("mkdir -p /media/disk/#{ARGV[1]}")
			retval = 1 unless system("mount /dev/#{ARGV[1]} /media/disk/#{ARGV[1]}")
		else
			retval = 1 unless system("umount /dev/#{ARGV[1]}") 
		end
	end
}

exit retval
