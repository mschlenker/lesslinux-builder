#!/usr/bin/ruby
# encoding: utf-8

class MfsDiskDrive
	
	def initialize(device, debug=false)
		@device = device
		@size = -1
		@partitions = Array.new
		@removable = nil
		@usb = nil
		@debug = debug
		@vendor = nil
		@model = nil
		@smart_errors = nil
		@smart_info = nil
		@smart_support = false
		@smart_test_types = nil
		@smart_test_results = nil
		@smart_bad_sectors = nil
		@smart_reallocated = nil
		@smart_seek_error = nil
		@gpt = false
		@mbr = false
		@trim = nil
		get_info
		read_partitions
	end
	attr_reader :device, :size, :partitions, :removable, :usb, :vendor, :model, :gpt, :mbr
	
	def read_partitions
		fullblocks = 0
		skiplist = Array.new
		if system("which parted > /dev/null") 
			IO.popen("parted -s '/dev/#{@device}' print") { |line|
				while line.gets
					ltoks = $_.strip.split
					if ltoks[0].to_i > 0 && ltoks[4] =~ /extended/i 
						skiplist.push(@device + ltoks[0])
						$stderr.puts "Adding #{ltoks[0]} to skiplist"
					end
				end
			}
		end
		IO.popen("cat /proc/partitions") { |line|
			while line.gets
				ltoks = $_.strip.split
				pmatch = Regexp.new("^" + @device + "\\d+$")
				qmatch = Regexp.new("^" + @device + "p\\d+$")
				rmatch = Regexp.new("^" + @device + "$")
				if ltoks[3] =~ pmatch || ltoks[3] =~ qmatch
					blocks = ltoks[2].to_i
					@partitions.push(MfsSinglePartition.new(@device, ltoks[3], blocks, true,@trim)) unless skiplist.include?(ltoks[3]) 
				elsif ltoks[3] =~ rmatch
					fullblocks = ltoks[2].to_i
				end
			end
		}
		if @partitions.size < 1 && system("blkid '/dev/#{@device}' > /dev/null ")
			@partitions.push(MfsSinglePartition.new(@device, @device, fullblocks, true, @trim))
		end
	end
	
	def get_info
		begin
			@vendor = File.new("/sys/block/" + @device + "/device/vendor").read.strip
		rescue
			@vendor = "NOVENDOR"
		end
		begin
			@model = File.new("/sys/block/" + @device + "/device/model").read.strip
		rescue
			@model = "NONAME"
		end
		@removable = false
		@removable = true if File.new("/sys/block/" + @device + "/removable").read.strip.to_i > 0
		@size = File.new("/sys/block/" + @device + "/size").read.strip.to_i * 512
		@usb = false
		@usb = true if File.readlink("/sys/block/" + @device) =~ /usb/ 
		trim?
		if @debug == true
			$stderr.puts "  vendor: " + @vendor.to_s + " " + @model.to_s
			$stderr.puts "  size:   " + @size.to_s 
			$stderr.puts "  remov.: " + @removable.to_s  
			$stderr.puts "  usb:    " + @usb.to_s 
		end
	end
	
	def human_size 
		if @size.to_f / 1024 ** 3 > 3
			return (@size.to_f / 1024 ** 3 + 0.5).to_i.to_s + "GB"
		elsif @size.to_f / 1024 ** 2 > 3
			return (@size.to_f / 1024 ** 2 + 0.5).to_i.to_s + "MB"
		end
		return @size.to_s + "B" 
	end
	
	def umount
		@partitions.each { |p| p.umount unless p.system_partition? }
	end
	
	def force_umount 
		@partitions.each { |p| p.force_umount unless p.system_partition? }
	end
	
	def error_log
		return @smart_support, @smart_info, @smart_errors unless @smart_errors.nil? 
		system("smartctl --smart=on --offlineauto=on --saveauto=on /dev/#{@device}")
		@smart_info = Array.new
		@smart_errors = Array.new
		IO.popen("smartctl -i /dev/#{@device}") { |l| @smart_info.push($_) while l.gets }
		IO.popen("smartctl --attributes --log=selftest --quietmode=errorsonly  /dev/#{@device}") { |l|
			while l.gets
				line = $_ 
				@smart_errors.push(line) unless line.strip == ""
			end
		}
		@smart_support = true if @smart_info.join(" ") =~ /SMART support is: Available/
		return @smart_support, @smart_info, @smart_errors
	end
	
	# test_types, bad_sectors, reallocated_sectors, seek_errors
	
	def smart_details 
		# @smart_test_types
		# @smart_test_results
		# @smart_bad_sectors
		# @smart_reallocated
		# @smart_seek_error
		
		inside = false
		IO.popen("smartctl -l selftest /dev/#{@device}") { |l|
			while l.gets
				line = $_.strip
				if inside == true && line =~/^\#/
					if line =~ /Short offline/ && @smart_test_types.nil?
						@smart_test_types = "short"
					end
					if (line =~ /Extended offline/ || line =~ /Extended captive/) \
							&& (@smart_test_types.nil? || @smart_test_types == "short") 
						@smart_test_types = "long"
					end
					if line =~ /Completed\: read failure/
						@smart_test_results = "error"
					end
				end
				inside = true if line =~ /START OF READ SMART DATA SECTION/
			end
		}
		inside = false
		IO.popen("smartctl --attributes /dev/#{device}") { |l|
			while l.gets
				line = $_.strip
				ltoks = line.split
				if inside == true && ltoks[0].to_i == 5 && ltoks[-1].to_i > 0
					@smart_reallocated = ltoks[-1].to_i
				elsif inside == true && ltoks[0].to_i == 7 && ltoks[-1].to_i > 100
					@smart_seek_error = ltoks[-1].to_i
				elsif inside == true && ltoks[0].to_i == 197 && ltoks[-1].to_i > 0
					@smart_reallocated = ltoks[-1].to_i
				end
				inside = true if line =~ /^ID\# ATTRIBUTE/
			end
		}
		return @smart_test_types, @smart_test_results, @smart_bad_sectors, @smart_reallocated, @smart_seek_error
	end
	
	def smart_short_test
		tremain = nil
		system("smartctl -X /dev/#{@device}")
		IO.popen("smartctl -s on -t short /dev/#{@device}") { |l|
			while l.gets
				if $_ =~ /^Please wait\s*?(\d*?)\s*?minutes/ 
					tremain = $1.to_i
				end
			end
		}
		return tremain
	end
	
	def mounted
		m = false
		@partitions.each { |p|
			m = true unless p.mount_point.nil?
		}
		return m
	end
	
	# Check for Intel Matrix Storage Manager
        
        def imsm? 
                return nil unless system("dd if=/dev/#{@device} bs=512 count=1 of=/dev/null")
		return true if File.exists?("/var/run/lesslinux/fake_imsm_#{@device}")
                return true if system("dd if=/dev/#{@device} bs=512 count=1 | strings | grep 'Intel IMSM NV Cache Cfg' ")
                return false
        end
        
        # Check if any NTFS partition is hibernated
        
        def hibernated?
                m = false
                @partitions.each { |p| 
                        return true if p.hibernated? == true
                        m = nil if p.hibernated?.nil?
                }
                return m 
        end
	
	# Check if a device supports TRIM?
	
	def trim?
		return @trim unless @trim.nil?
		trim = false
		return nil unless system("which hdparm > /dev/null")
		IO.popen("hdparm -I /dev/#{device}") { | l| 
			while l.gets
				begin
					line = $_.strip
					trim = true if line =~ /data set management trim supported/i
				rescue
					$stderr.puts "Failed to parse line..."
				end
			end
		}
		@trim = trim 
		return trim 
	end

end