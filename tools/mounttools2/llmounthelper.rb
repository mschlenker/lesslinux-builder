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
	drives.push(MfsDiskDrive.new(l, true)) if l =~ /sr[0-9]$/ 
}

drives.each { |d|
	d.partitions.each { |p|
		if p.device == ARGV[1] && subcommand == "mount"
			if ARGV[2].to_s == "rw" 
				p.mount("rw", "/media/disk/" + p.device, 1000, 1000)
			else
				p.mount("ro", "/media/disk/" + p.device, 1000, 1000)
			end
		elsif p.device == ARGV[1] && subcommand == "umount"
			unless p.umount
				p.force_umount
			end
		end
	}
}