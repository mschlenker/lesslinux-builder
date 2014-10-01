#!/usr/bin/ruby
# encoding: utf-8

require 'MfsDiskDrive'
require 'MfsSinglePartition'
require "rexml/document"
include REXML

class XmlDriveList
	
	def initialize
		@drives = nil
		reread_drives
	end
	# attr_reader :outer_vbox
	
	def reread_drives
		@drives = Array.new
		Dir.entries("/sys/block").each { |l|
			if l =~ /[a-z]$/ 
				begin
					d =  MfsDiskDrive.new(l, true)
					@drives.push(d) 
				rescue 
					$stderr.puts "Failed adding: #{l}"
				end
			end
		}
		Dir.entries("/sys/block").each { |l|
			if ( l =~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/ )
				begin 
					d =  MfsDiskDrive.new(l, true)
					@drives.push(d) 
				rescue 
					$stderr.puts "Failed adding: #{l}"
				end
			end
		}
		Dir.entries("/sys/block").each { |l|
			if l =~ /sr[0-9]$/ 
				begin 
					d =  MfsDiskDrive.new(l, true)
					@drives.push(d) 
				rescue 
					$stderr.puts "Failed adding: #{l}"
				end
			end
		}
	end
	
	def dump_xml
		doc = Document.new "<drivelist></drivelist>"
		@drives.each { |d|
			n = doc.root.add_element("drive") 
			n.add_attribute("dev", d.device) 
			n.add_attribute("vendor", d.vendor) unless d.vendor.nil?
			n.add_attribute("model", d.model) unless d.model.nil?	
			n.add_attribute("usb", d.usb.to_s) unless d.usb.nil?
			n.add_attribute("size", d.size) if d.size > -1
			n.add_attribute("hsize", d.human_size) if d.size > -1
			d.partitions.each { |p|
				mounted = p.mount_point
				m = n.add_element("partition")
				m.add_attribute("dev", p.device)
				unless mounted.nil?
					m.add_attribute("mountpoint", mounted[0])
					m.add_attribute("mountopts", mounted[1].join(" "))
					m.add_attribute("rw", "true") if mounted[1].include?("rw")
					m.add_attribute("rw", "false") if mounted[1].include?("ro")
					p.retrieve_occupation
					m.add_attribute("free", p.free) if p.free > -1
				else 
					m.add_attribute("hibernated", "true") if p.hibernated? 
				end
				m.add_attribute("system", "true") if p.system_partition?
				# iswin, winvers = p.is_windows
				# m.add_attribute("windows", winvers) if iswin == true
				m.add_attribute("size", p.size) if p.size > -1
				m.add_attribute("hsize", p.human_size) if p.size > -1
				m.add_attribute("label", p.label) unless p.label.nil?
				m.add_attribute("fs", p.fs) unless p.fs.nil?
			}
			if (d.device =~  /^sr[0-9]/ && d.partitions.size < 1)
				m = n.add_element("partition")
				m.add_attribute("dev", d.device)
				m.add_attribute("fs", "iso9660")
				m.add_attribute("label", "no media")
			end
		}
		doc.write( $stdout, 2 )
	end
	
end
