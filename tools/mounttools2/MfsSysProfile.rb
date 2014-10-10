#!/usr/bin/ruby
# encoding: utf-8

require 'MfsDiskDrive'
require 'MfsSinglePartition'
require 'rexml/document'
require 'net/http'

class MfsSysProfile
	def initialize(usb=true, pci=true, dmi=true, hdd=true, monitor=true)
		@uuid = nil
		@version = "none"
		@version = File.new("/etc/lesslinux/updater/version.txt").read.strip if File.exists?("/etc/lesslinux/updater/version.txt")
		if File.exists?("/var/run/lesslinux/uuid") 
			@uuid = File.new("/var/run/lesslinux/uuid").read.strip
		else
			@uuid = `uuidgen`.strip
			system("mkdir -p /var/run/lesslinux")
			f = File.new("/var/run/lesslinux/uuid", "w")
			f.write(@uuid)
			f.close
		end
		@usb = usb
		@usb_devs = Array.new
		@usb_devs = get_usb if usb == true
		@pci = pci
		@pci_devs = Array.new
		@pci_devs = get_pci if pci == true
		@hdd = hdd
		@hdd_devs = Array.new
		@hdd_devs = get_hdd if hdd == true 
		@dmi = dmi
		@dmi_lines = Array.new
		@dmi_lines = get_dmi if dmi == true
		@monitor = monitor
		@monitor_res = get_resolution if monitor == true
	end		
	attr_reader  :uuid, :usb, :usb_devs, :pci, :pci_devs , :dmi, :dmi_lines 
	
	def get_usb
		devs = Array.new
		IO.popen("lsusb") { |l|
			while l.gets 
				if $_.strip =~ /.*?\s([0-9a-f]{4}\:[0-9a-f]{4})\s/
					devs.push $1
				end
			end
		}
		return devs.uniq
	end
	
	def get_pci
		devs = Array.new
		IO.popen("lspci -nn") { |l|
			while l.gets 
				dtoks = Array.new
				# 01:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Park [Mobility Radeon HD 5430/5450/5470] [1002:68e0]
				if $_.strip =~ /^[0-9a-f]{2}\:[0-9a-f]{2}\.[0-9a-f]\s(.*?)\s\[([0-9a-f]{4})\]\:\s(.*?)\s\[([0-9a-f]{4}\:[0-9a-f]{4})\]/ 
					dtoks.push $1
					dtoks.push $2
					dtoks.push $3
					dtoks.push $4
					devs.push dtoks 
				end
			end
		}
		return devs
	end
	
	def get_dmi
		lines = Array.new
		IO.popen("dmidecode -q") { |l|
			while l.gets 
				line = $_
				lines.push(line) unless line.strip =~ /^Serial Number\:/ ||  line.strip =~ /^Asset Tag\:/ ||  line.strip =~ /^UUID\:/ 
			end
		}
		return lines 
	end
	
	def get_hdd
		drives = Array.new
		Dir.entries("/sys/block").each { |l|
			if l =~ /[a-z]$/ ||  l=~ /mmcblk[0-9]$/ ||  l =~ /mmcblk[0-9][0-9]$/
				begin
					d =  MfsDiskDrive.new(l, true)
					drives.push(d) 
				rescue 
					$stderr.puts "Failed adding: #{l}"
				end
			end
		}
		return drives 
	end
	
	def get_resolution
		# 1920x1080      60.0*+   50.0     59.9     50.0     60.0
		res = nil
		IO.popen("xrandr") { |l|
			while l.gets 
				line = $_.strip
				if line =~ /([0-9]{3,5}x[0-9]{3,4}).*?\*/
					res = $1
				end
			end
		}
		return res
	end
	
	def get_xml(indent=nil)
		x = REXML::Document.new
		r = x.add_element("llsysprofile")
		g = r.add_element("general")
		g.add_attribute("version", "1.0.0")
		g.add_attribute("uuid", @uuid)
		g.add_attribute("build", @version)
		d = r.add_element("dmidecode")
		d.add(REXML::CData.new(@dmi_lines.join("")))
		pci = r.add_element("pci")
		@pci_devs.each { |n| 
			pcidev = pci.add_element("dev")
			pcidev.add_attribute("id", n[3])
			pcidev.add_attribute("cls", n[1])
			pcidev.add_attribute("niceclass", n[0])
			pcidev.add_attribute("nicename", n[2])
		}
		usb = r.add_element("usb")
		@usb_devs.each { |n| 
			usbdev = usb.add_element("dev")
			usbdev.add_attribute("id", n) 
		}
		disks = r.add_element("disks")
		@hdd_devs.each { |d|
			smart_support, smart_info, smart_errors = d.error_log
			if smart_support == true
				hdd = disks.add_element("disk")
				hdd.add_attribute("vendor", d.vendor)
				hdd.add_attribute("model", d.model)
				hdd.add_attribute("size", d.size.to_s)
				hdd.add_attribute("trim", d.trim?.to_s)
				hdd.add_attribute("errors", smart_errors.size.to_s)
			end
		}
		m = r.add_element("monitors")
		unless @monitor_res.nil?
			mon = m.add_element("monitor")
			mon.add_attribute("resolution", @monitor_res) 
		end
		# x.write $stderr, 4 
		return x
	end
	
	def send(url, email=nil)
		res = Net::HTTP.post_form(URI(url), 'email' => email.to_s, 'sysprofile' => get_xml.to_s)
		return res.body
	end
end