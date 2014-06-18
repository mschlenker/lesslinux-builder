#!/usr/bin/ruby
# encoding: utf-8

require "tmpdir"

class MfsSamDatabase
	
	def initialize(partition, path)
		@partition = partition
		@samfile = path
		@samusers = nil
	end
	
	attr_reader :partition, :samfile 
	
	def read_users 
		return @samusers unless @samusers.nil?
		puts @partition.device
		was_mounted = true
		if @partition.mount_point.nil?
			was_mounted = false
			@partition.mount
		end
		puts @partition.mount_point[0] 
		mnt = @partition.mount_point 
		@samusers = Array.new
		IO.popen("printf 'q\n' | chntpw -l '" + mnt[0] + "/" + @samfile + "'") { |io|
			accstart = false
			while io.gets
				toks = $_.split("|")
				if accstart == true
					$stderr.puts "Hex ID:" + toks[1].to_s.strip
					$stderr.puts "Username: " + toks[2].to_s.strip.gsub(/[^[:print:]]/, '_')
					@samusers.push( [ toks[1].to_s.strip, toks[2].to_s.strip.gsub(/[^[:print:]]/, '_') ] )
				end
				accstart = true if $_ =~ / ^|\sRID/
			end
		}
		@partition.umount if was_mounted == false
		return @samusers 
	end
	
	def reset(hexid, backup=false)
		was_mounted = true
		if @partition.mount_point.nil?
			was_mounted = false
			@partition.mount("rw") 
		end
		return false unless @partition.remount_rw
		if backup == true
			now = Time.new.to_i
			return false unless system("cp '#{@partition.mount_point[0]}/#{@samfile}' '#{@partition.mount_point[0]}/#{@samfile}.#{now.to_s}'") 
		end
		exstring = "printf \"1\\ny\\n\" | chntpw -u 0x" + hexid + " '" + @partition.mount_point[0] + "/" + @samfile + "'"
		$stderr.puts "RESET HIVE: " + exstring
		system(exstring)
		retval = $?.exitstatus
		$stderr.puts "RETURNED: " + retval.to_s
		@partition.umount if was_mounted == false
		return true if retval == 2
		return false
	end
	
end