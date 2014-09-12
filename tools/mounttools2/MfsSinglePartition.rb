#!/usr/bin/ruby
# encoding: utf-8

require "tmpdir"
require "MfsSamDatabase" 
require "MfsRegistryDatabase" 

class MfsSinglePartition
	
	def initialize(parent, device, blocks, debug=false, trim=nil)
		@parent = parent
		@device = device
		@debug = debug
		@blocks = blocks
		@enc = nil
		@fs = nil
		@uuid = nil
		@label = nil
		@size = -1
		@filesyssize = -1
		@free = -1
		@mounted = nil
		@fct = nil
		@winpart = nil
		@winvers = nil
		@extended = false
		@trim = trim
		blkid
	end
	attr_reader :device, :blocks, :fs, :uuid, :label, :size, :extended, :parent, :trim, :free
	
	def blkid
		@size = File.new("/sys/block/" + @parent + "/size").read.to_i * 512
		@size = File.new("/sys/block/" + @parent + "/" + @device + "/size").read.to_i * 512 if File.exist?("/sys/block/" + @parent + "/" + @device + "/size") 
		IO.popen("blkid -o udev /dev/" + @device) { |line|
			while line.gets
				ltoks = $_.strip.split('=')
				@uuid = ltoks[1] if ltoks[0] == "ID_FS_UUID"
				@label = ltoks[1] if ltoks[0] == "ID_FS_LABEL"
				@fs = ltoks[1] if ltoks[0] == "ID_FS_TYPE"
				@enc = false
				@enc = true if @fs == "crypto_LUKS"
			end
		}
		if @uuid.nil? && @size == 1024
			@extended = true 
		end
		if @uuid.nil? && @label.nil?
			@uuid = "nil" + rand(999_999_999).to_s 
		elsif @uuid.nil?
			@uuid = @label
		end
		if @debug == true
			$stderr.puts "  part:    " + @device.to_s
			$stderr.puts "    size:  " + @size.to_s
			$stderr.puts "    uuid:  " + @uuid.to_s 
			$stderr.puts "    fs:    " + @fs.to_s
			$stderr.puts "    label: " + @label.to_s
			$stderr.puts "    enc:   " + @enc.to_s
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
	
	def is_windows
		return false, nil unless @fs =~ /fat/ || @fs =~ /ntfs/
		return @winpart, @winvers unless @winpart.nil?
		mnt = mount_point
		if mnt.nil?
			was_mounted = false
			mount 
			mnt = mount_point
			return false, nil if mnt.nil?
		else
			# return false, nil if mnt.nil?
			was_mounted = true
		end
		winfiles = Array.new
		return false, nil unless File.exist?("/usr/share/lesslinux/drivetools/winfiles.txt")
		File.open("/usr/share/lesslinux/drivetools/winfiles.txt").each { |line| winfiles.push(line.strip) unless line.strip == "" } 
		# if mount_point.nil?
		#	was_mounted = false
		#	mount
		# end
		windir = nil
		sysdir = nil
		[ "Windows", "WINDOWS", "windows"].each { |w| windir = w if File.directory?(mount_point[0] + "/" + w) }
		if windir.nil?
			umount if was_mounted == false
			@winpart = false
			return false, nil
		end
		[ "System32", "SYSTEM32", "system32" ].each { |s| sysdir = mount_point[0] + "/" + windir + "/" + s if File.directory?(mount_point[0] + "/" + windir + "/" + s) }
		if sysdir.nil?
			umount if was_mounted == false
			@winpart = false
			return false, nil
		end
		ntoskrnl = nil
		[ "ntoskrnl.exe", "NTOSKRNL.EXE", "Ntoskrnl.exe" ].each { |n| ntoskrnl = sysdir + "/" + n if File.exists?(sysdir + "/" + n) }
		sixtyfour = false
		foundfiles = Array.new
		# $stderr.puts "Sysdir: " + sysdir
		Dir.entries(sysdir).each { |f| 
			# $stderr.puts f.strip.downcase
			foundfiles.push(f.strip.downcase)
			ntoskrnl = sysdir + "/" + f.strip if f.strip.downcase =~ /ntoskrnl\.exe/
		}
		IO.popen("strings '#{ntoskrnl}' ") { |line|
			while line.gets
				@winvers = "Windows XP" if $_.strip =~ /[0-9][0-9][0-9][0-9]\.xp(.*?)(rtm|gdr|qfe)\./
				@winvers = "Windows XP" if $_.strip =~ /^2600\.xp(.*?)\./
				@winvers = "Windows Vista" if $_.strip =~ /[0-9][0-9][0-9][0-9]\.vista(.*?)(rtm|gdr)\./
				@winvers = "Windows 7" if $_.strip =~ /[0-9][0-9][0-9][0-9]\.win7(.*?)(rtm|gdr)\./
				@winvers = "Windows 8" if $_.strip =~ /[0-9][0-9][0-9][0-9]\.win8(.*?)(rtm|gdr)\./
			end
		}
		intersect = foundfiles & winfiles
		# $stderr.puts "Intersection: " + intersect.size.to_s 
		if intersect.size.to_f < winfiles.size.to_f * 0.95 && @winvers.nil?
			umount if was_mounted == false
			@winpart = false
			return false, nil
		end
		umount if was_mounted == false
		@winpart = true
		@winvers = "Windows (unknown)" if @winvers.nil? 
		return @winpart, @winvers
	end
	
	def samfile
		iswin, winver = is_windows
		return nil unless iswin
		was_mounted = true
		if mount_point.nil?
			was_mounted = false
			mount
		end
		windir = nil
		sysdir = nil
		cfgdir = nil
		samfile = nil
		[ "Windows", "WINDOWS", "windows"].each { |w| windir = w if File.directory?(mount_point[0] + "/" + w) }
		[ "System32", "SYSTEM32", "system32" ].each { |s| sysdir = windir + "/" + s if File.directory?(mount_point[0] + "/" + windir + "/" + s) }
		[ "Config", "CONFIG", "config" ].each { |c| cfgdir = sysdir + "/" + c if File.directory?(mount_point[0] + "/" + sysdir + "/" + c) }
		puts cfgdir.to_s 
		if cfgdir.nil? 
			umount if was_mounted == false
			return nil 
		end
		[ "Sam", "SAM", "sam" ].each { |f| samfile = cfgdir + "/" + f if File.exists?(mount_point[0] + "/" + cfgdir + "/" + f) }
		if samfile.nil?
			umount if was_mounted == false
			return nil 
		end
		samobj = MfsSamDatabase.new(self, samfile)
		return samobj
	end
	
	def regfile(names=nil)
		names = [ "Software", "SOFTWARE", "software" ] if names.nil?
		iswin, winver = is_windows
		return nil unless iswin
		was_mounted = true
		if mount_point.nil?
			was_mounted = false
			mount
		end
		windir = nil
		sysdir = nil
		cfgdir = nil
		winfile = nil
		[ "Windows", "WINDOWS", "windows"].each { |w| windir = w if File.directory?(mount_point[0] + "/" + w) }
		[ "System32", "SYSTEM32", "system32" ].each { |s| sysdir = windir + "/" + s if File.directory?(mount_point[0] + "/" + windir + "/" + s) }
		[ "Config", "CONFIG", "config" ].each { |c| cfgdir = sysdir + "/" + c if File.directory?(mount_point[0] + "/" + sysdir + "/" + c) }
		puts cfgdir.to_s 
		if cfgdir.nil? 
			umount if was_mounted == false
			return nil 
		end
		names.each { |f| winfile = cfgdir + "/" + f if File.exists?(mount_point[0] + "/" + cfgdir + "/" + f) }
		if winfile.nil?
			umount if was_mounted == false
			return nil 
		end
		regobj = MfsRegistryDatabase.new(self, winfile)
		return regobj
	end
	
	def mount(mode="ro", mntpnt=nil, uid=nil, gid=nil, extopts=nil, lukspw=nil)
		if @fs =~ /swap/
			return false unless mode == "rw"
			return true if system("swapon /dev/" + @device)
			return false
		end
		mountpoint = ""
		if mntpnt.nil?
			mountpoint = "/media/" + @uuid
			system("mkdir -p /media/" + @uuid)
		else
			mountpoint = mntpnt
			system("mkdir -p \"#{mntpnt}\"")
		end
		type = ""
		opts = [ mode ]
		if @fs =~ /crypto_LUKS/
			return false if lukspw.nil?
			return false unless system("echo '" + lukspw.gsub("'", "\\\\" + '\'') + "' | cryptsetup luksOpen -q /dev/" + @device + " " + @device )
			# Just mount without further specifying arguments - this is suboptimal
			# for ext2/ext3 since those are better mounted using the ext4 driver
			return true if system("mount /dev/mapper/" + @device + " -o #{mode} '" +  mountpoint + "'" )
			return false
		elsif @fs =~ /fat/
			type = "-t vfat"
			opts.push "iocharset=utf8"
			opts.push("uid=#{uid.to_s}") unless uid.nil?
			opts.push("gid=#{gid.to_s}") unless uid.nil?
		elsif @fs =~ /ntfs/
			type = "-t ntfs-3g"
			opts.push "utf8"
			opts.push("uid=#{uid.to_s}") unless uid.nil?
			opts.push("gid=#{gid.to_s}") unless uid.nil?
		elsif @fs =~ /ext/
			type = "-t ext4"
		else
			type = ""
		end
		opts = opts + extopts unless extopts.nil? 
		mountcmd = "mount " + type + " -o " + opts.join(',') + " /dev/" + @device + " '" + mountpoint + "'"
		return true if system(mountcmd)
		return false
	end
	
	def umount
		if @fs =~ /swap/
			return true if system("swapoff /dev/" + @device)
			return false
		elsif @fs =~ /crypto_LUKS/ 
			system("sync")
			system("umount /dev/mapper/" + @device) 
			return true if system("cryptsetup luksClose /dev/mapper/" + @device) 
			return false 
		end
		return true if system("umount /dev/" + @device)
		return false
	end
	
	def force_umount
		return umount if @fs =~ /swap/ 
		return true if mount_point.nil?
		return true if umount
		mnt_point = mount_point
		unless mnt_point.nil? 
			system("fuser -k #{mnt_point}")
		end
		return umount
	end
	
	def remount_ro
		return false if mount_point.nil?
		return true if mount_point[1].include?("ro") 
		system("mount -o remount,ro #{mount_point[0]}") unless @fs =~ /ntfs/
		return true if mount_point[1].include?("ro") 
		mnt = mount_point		
		mnt[1].delete("rw")
		force_umount 
		return mount("ro", mnt[0], nil, nil, mnt[1])
	end
	
	def remount_rw
		return false if mount_point.nil?
		return true if mount_point[1].include?("rw") 
		system("mount -o remount,rw #{mount_point[0]}") unless @fs =~ /ntfs/
		return true if mount_point[1].include?("rw") 
		mnt = mount_point		
		mnt[1].delete("ro")
		force_umount 
		return mount("rw", mnt[0], nil, nil, mnt[1])
	end
	
	def mount_point
		IO.popen("cat /proc/mounts") { |line|
			while line.gets
				ltoks = $_.strip.split 
				device = ltoks[0]
				if File.symlink?(device)
					target = File.readlink(device)
					if target =~ /^\//
						device = target
					else
						abspath = File.dirname(device) + "/" + target 
						device = File.realpath(abspath)
					end
				end
				if device == "/dev/" + @device || device == @device || device == "/dev/mapper/" + @device
					# $stderr.puts @device + " is mounted on " + ltoks[1].gsub('\040', '').gsub('\134', '\\')
					return [ ltoks[1].gsub('\040', ' ').gsub('\134', '\\'), ltoks[3].split(',') ]
				end
			end
		}
		IO.popen("cat /proc/swaps") { |line|
			while line.gets 
				ltoks = $_.strip.split 
				device = ltoks[0]
				if device == "/dev/" + @device || device == @device || device == "/dev/mapper/" + @device
					# $stderr.puts @device + " is mounted on " + ltoks[1].gsub('\040', '').gsub('\134', '\\')
					return [ "/media/swap", [ "rw" ] ]
				end
			end
		}
		return nil
	end
	
	def mounted
		return false if mount_point.nil? 
		return true
	end
	
	def fssize
		return @filesyssize unless @filesyssize < 0
		if mount_point.nil?
			mount("ro")
			retrieve_occupation
			umount
		else
			retrieve_occupation
		end
		return @filesyssize
	end
	
	def free_space
		return @free unless @free < 0
		if mount_point.nil?
			mount("ro")
			retrieve_occupation
			umount
		else
			retrieve_occupation
		end
		return @free
	end
	
	def retrieve_occupation
		mnt = mount_point
		return 0 if mnt.nil?
		IO.popen("df -k '" + mnt[0] + "' | tail -n1 ") { |line|
			while line.gets
				ltoks = $_.strip.split
				@filesyssize = ltoks[1].to_i * 1024
				@free = ltoks[3].to_i * 1024
			end
		}
		$stderr.puts "Whole: " + @filesyssize.to_s + " Free: " + @free.to_s 
		return @free
	end
	
	def filecount(pgbar=nil)
		return @fct unless @fct.nil?
		return @fct unless @fs =~ /ext|fat|btrfs|ntfs|reiser/
		unless mount_point.nil?
			$stderr.puts "Count " + @device
			count_files(pgbar)
		else
			mount("ro")
			$stderr.puts "Mount and count " + @device
			count_files(pgbar)
			umount
		end
		return @fct
	end
	
	def count_files(pgbar=nil)
		dir = mount_point[0]
		file_counter = 0 
		pgbar.activity_mode = true unless pgbar.nil?
		last_pulse = Time.now.to_f
		IO.popen("find '" + dir + "' -xdev -type f ") { |f|
			while f.gets
				file_counter += 1
				unless pgbar.nil?
					now = Time.now.to_f
					if now - last_pulse > 0.1
						last_pulse = now
						pgbar.text = "Analysiere Laufwerk #{@device} - #{file_counter.to_s} Dateien gefunden" 
						# $stderr.puts "Dateien auf " + @device + ": " + file_counter.to_s 
						pgbar.pulse
						while Gtk.events_pending?
							Gtk.main_iteration
						end
					end
				end
			end
		}
		file_counter = nil if $?.nil?
		pgbar.activity_mode = false unless pgbar.nil?
		pgbar.fraction = 1.0 unless pgbar.nil?
		@fct = file_counter 
	end
	
	def system_partition?
		mnt = mount_point
		return false if mnt.nil?
		# Every drive mounted at /home or under /lesslinux is considered as system drive
		return true if mnt[0] =~ /^\/lesslinux\// || mnt[0] =~ /^\/home$/ 
		# Consider all encrypted swap space as system drive
		return true if @fs =~ /crypto_LUKS/i && mnt[0] =~  /^\/media\/swap/ 
		return false
	end
	
	def hibernated?
		return true if File.exists?("/var/run/lesslinux/fake_hibernation_#{@device}") 
		return false unless @fs =~ /ntfs/i 
		return nil unless system("ntfs-3g.probe --help")
		system("ntfs-3g.probe --readwrite /dev/#{@device}")
		ret = $?
		if ret.exitstatus == 14
			return true
		elsif ret.exitstatus == 19
			return nil
		end
		return false
	end	
	
	def remove_hiberfil
		return false unless @fs =~ /ntfs/i 
		return nil unless mount_point.nil? 
		return nil unless system("ntfs-3g.probe --help")
		system("mkdir -p /var/run/Lesslinux/remove_hiberfil")
		system("mount -t ntfs-3g -o rw,remove_hiberfile /dev/#{@device} /var/run/Lesslinux/remove_hiberfil") 
		system("umount /var/run/Lesslinux/remove_hiberfil") 
		if system("mountpoint -q /var/run/Lesslinux/remove_hiberfil") 
			sleep 2
			system("umount -f /var/run/Lesslinux/remove_hiberfil") 
		end
		return true
	end
	
	def zero_free(pgbar=nil)
		return false if mounted
		rndstr = Random.rand(100_000_000).to_s
		mount("rw")
		mntpnt = mount_point[0]
		return false if mntpnt.nil?
		system("mkdir '#{mntpnt}/#{rndstr}'")
		toks =  free_space / 67108864
		0.upto(toks) { |n|
			unless pgbar.nil? 
				pgbar.fraction = n.to_f / toks.to_f 
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
			end
			system("dd if=/dev/zero bs=1M count=64 of='#{mntpnt}/#{rndstr}/#{n.to_s}.nul'") unless File.exists?("/var/run/lesslinux/stop.zeroing") 
		}
		system("sync")
		system("rm -rf '#{mntpnt}/#{rndstr}'")
		umount
		return true
	end
	
	def trim?
		return @trim 
	end
end
