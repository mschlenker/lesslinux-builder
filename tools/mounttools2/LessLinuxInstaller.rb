#!/usr/bin/ruby
# encoding: utf-8

require "tmpdir"
require "MfsSinglePartition"
require "MfsDiskDrive"
require 'MfsTranslator.rb'

class LessLinuxInstaller

	def initialize(device, pgbar=nil)
		@dev = device
		@pgbar = pgbar
		@xbranding = File.new( "/etc/lesslinux/branding/branding.xml" )
		@branding = REXML::Document.new  @xbranding
		@language = ENV['LANGUAGE'][0..1]
		tlfile = "LessLinuxInstaller.xml"
		tlfile = "/usr/share/lesslinux/drivetools/LessLinuxInstaller.xml" if File.exists?("/usr/share/lesslinux/drivetools/LessLinuxInstaller.xml")
		@tl = MfsTranslator.new(@language, tlfile)
	end
	attr_reader :dev, :branding
	
	def calculate_min_size 
		sysmount = ""
		[ "/lesslinux/cdrom", "/lesslinux/isoloop" ].each { |m|
			sysmount = m if system("mountpoint -q #{m}")
		}
		sysdev = ` df -k #{sysmount} | tail -n1 `.strip.split[0].to_s
		isosize = ` df -k #{sysmount} | tail -n1 `.strip.split[2].to_i * 1024  
		efisize = ` ls -lak #{sysmount}/boot/efi/efi.img `.strip.split[4].to_i 
		bootsize = ` du -k #{sysmount}/boot | tail -n1 `.strip.split[0].to_i * 1024
		padsize = 1024 ** 2 * 128
		minsize = isosize + bootsize + efisize + padsize
		puts "#{minsize.to_s}: #{isosize.to_s} #{bootsize.to_s} #{efisize.to_s} #{padsize.to_s}"
		isoblocks = isosize / ( 1024 ** 2 * 8 ) + 1
		bootblocks = bootsize / ( 1024 ** 2 * 8 ) + 4
		efiblocks = efisize / ( 1024 ** 2 * 8 ) + 1
		return minsize, isoblocks, bootblocks, efiblocks, sysdev, sysmount 
	end

	def run_command(command, args, text=nil)
		puts "Running " + command + " : " + args.join(" ")  
		if @pgbar.nil?
			c = args.map { |x| "'" + x + "'" }
			system c.join(" ")
		else
			@pgbar.text = text 
			vte = Vte::Terminal.new
			running = true
			vte.signal_connect("child_exited") { running = false }
			vte.fork_command(command, args)
			while running == true
				@pgbar.pulse
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				sleep 0.2 
			end
		end	
	end
	
	def run_installation(language, contsizes, pgbar=nil, check=false) 
		tgt = @dev 
		sizes = calculate_min_size
		checklist = Array.new
		infostart = sizes[1] * 8388608
		bootstart =  ( sizes[1] + 8) * 8388608
		infoend = bootstart - 1
		efistart = ( sizes[1] + 8 + sizes[2] ) * 8388608
		bootend = efistart - 1  
		efiend = ( sizes[1] + 8 + sizes[2] + sizes[3]) * 8388608 - 1
		# blank the fist few MB
		# ddstr = "dd if=/dev/zero of=/dev/#{tgt.device} bs=1024 count=1024"
		run_command("dd", [ "dd", "if=/dev/zero", "of=/dev/#{tgt.device}", "bs=1024", "count=1024", "conv=sync" ] , @tl.get_translation("preparing")) 
		# puts ddstr 
		# system ddstr 
		# blank the last few MB
		tgtblocks = tgt.size / 1024 - 1024 
		puts tgtblocks.to_s 	
		# ddstr = "dd if=/dev/zero of=/dev/#{tgt.device} bs=1024 seek=#{tgtblocks.to_s}"
		# puts ddstr 
		# system ddstr 
		run_command("dd", [ "dd", "if=/dev/zero", "of=/dev/#{tgt.device}", "bs=1024", "seek=#{tgtblocks.to_s}", "conv=sync" ] , @tl.get_translation("preparing")) 
	
		# Copy the ISO image
		0.upto(sizes[1] - 1) { |b|
			system("rm /var/run/lesslinux/copyblock.bin")
			system("rm /var/run/lesslinux/checkblock.bin")
			system("dd if=#{sizes[4]} of=/var/run/lesslinux/copyblock.bin bs=8388608 count=1 skip=#{b.to_s} conv=sync")
			md5in = ` md5sum /var/run/lesslinux/copyblock.bin `.strip.split[0] 
			md5out = ''
			tries = 0
			matched = false
			while tries < 9 && matched == false 
				system("dd of=/dev/#{tgt.device} if=/var/run/lesslinux/copyblock.bin bs=8388608 count=1 seek=#{b.to_s}")
				system("dd if=/dev/#{tgt.device} of=/var/run/lesslinux/checkblock.bin bs=8388608 count=1 skip=#{b.to_s}")
				md5out = ` md5sum /var/run/lesslinux/checkblock.bin `.strip.split[0]
				if md5in == md5out 
					matched = true
				else
					puts "ERROR WRITING #{b.to_s} - TRY #{tries.to_s}"
				end
				tries += 1 
			end
			system("sync") 
			# ddstr = "dd if=#{sizes[4]} of=/dev/#{tgt.device} bs=8388608 count=1 seek=#{b.to_s} skip=#{b.to_s}" 
			# puts ddstr 
			# system ddstr 
			percentage = b * 100 / ( sizes[1] - 1 ) 
			unless pgbar.nil? 
				pgbar.text =  @tl.get_translation("installsys") + " - #{percentage.to_s}%"
				pgbar.fraction = b.to_f / ( sizes[1] - 1 ).to_f 
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
			end
		}
		system("rm /var/run/lesslinux/copyblock.bin")
		system("rm /var/run/lesslinux/checkblock.bin")
	
		# Blank the first 32k 
		system("dd if=/dev/zero bs=8192 count=4 of=/dev/#{tgt.device} conv=sync")
		# Create the boot partition legacy
		run_command("parted", [ "parted", "-s", "/dev/#{tgt.device}", "unit", "B", "mklabel", "gpt" ] , @tl.get_translation("partitioning")) 
		run_command("parted", [ "parted", "-s", "/dev/#{tgt.device}", "unit", "B", "mkpart", "info", "fat32", "#{infostart}", "#{infoend}" ] , @tl.get_translation("partitioning")) 
		run_command("parted", [ "parted", "-s", "/dev/#{tgt.device}", "unit", "B", "mkpart", "oldboot", "ext2", "#{bootstart}", "#{bootend}" ] , @tl.get_translation("partitioning")) 
		run_command("parted", [ "parted", "-s", "/dev/#{tgt.device}", "unit", "B", "set", "2", "legacy_boot", "on" ] , @tl.get_translation("partitioning")) 
		run_command("parted", [ "parted", "-s", "/dev/#{tgt.device}", "unit", "B", "mkpart", "efiboot", "fat32", "#{efistart}", "#{efiend}" ] , @tl.get_translation("partitioning")) 
		run_command("parted", [ "parted", "-s", "/dev/#{tgt.device}", "unit", "B", "set", "3", "boot", "on" ] , @tl.get_translation("partitioning")) 
		system("sync") 
		system("partprobe /dev/#{tgt.device}")
		run_command("/bin/sleep", [ "/bin/sleep", "5" ], @tl.get_translation("waiting"))
		while File.blockdev?("/dev/#{tgt.device}2") == false 
			run_command("/bin/sleep", [ "/bin/sleep", "5" ], @tl.get_translation("waiting"))
		end
		run_command("mkfs.ntfs", [ "mkfs.ntfs", "-F", "-f", "-L", "info", "/dev/#{tgt.device}1" ] , @tl.get_translation("write_info")) 
		# tar the content of the legacy boot part 
		run_command("mkfs.ext2", [ "mkfs.ext2", "-F", "/dev/#{tgt.device}2" ] , @tl.get_translation("write_boot")) 
		system("sync") 
		run_command("/bin/sleep", [ "/bin/sleep", "5" ], @tl.get_translation("waiting"))
		system("mkdir -p /var/run/lesslinux/install_boot")
		system("mount -t ext4 /dev/#{tgt.device}2 /var/run/lesslinux/install_boot")
		run_command("/bin/sleep", [ "/bin/sleep", "5" ], @tl.get_translation("waiting"))
		while system("mountpoint /var/run/lesslinux/install_boot") == false
			system("mount -t ext4 /dev/#{tgt.device}2 /var/run/lesslinux/install_boot")
			run_command(pgbar, "/bin/sleep", [ "/bin/sleep", "5" ], @tl.get_translation("waiting"))
		end
		run_command("rsync", [ "rsync", "-avHP", "#{sizes[5]}/boot", "/var/run/lesslinux/install_boot/" ] , @tl.get_translation("write_boot")) 
		system("sync") 
		system("chmod -R 0644 /var/run/lesslinux/install_boot/")
		run_command("dd", [ "dd", "if=#{sizes[5]}/boot/efi/efi.img", "of=/dev/#{tgt.device}3", "conv=sync" ], @tl.get_translation("write_boot")) 
		system("sync") 
		run_command("/bin/sleep", [ "/bin/sleep", "5" ], @tl.get_translation("waiting"))
		system("mkdir -p /var/run/lesslinux/install_efi")
		system("mount -t vfat /dev/#{tgt.device}3 /var/run/lesslinux/install_efi")
		# Find and move config files 
		cfgfiles = Array.new
		IO.popen("find /var/run/lesslinux/install_boot/boot -name '*.cfg'") { |line|
			while line.gets
				cfgfiles.push $_.strip
			end
		}
		IO.popen("find /var/run/lesslinux/install_efi -name '*.conf'") { |line|
			while line.gets
				cfgfiles.push $_.strip
			end
		}
		cfgfiles.push("/var/run/lesslinux/install_boot/boot/isolinux/extlinux.conf") if File.exists? ("/var/run/lesslinux/install_boot/boot/isolinux/extlinux.conf") 
		cfgfiles.each { |fname|
			puts "Editing: " + fname 
			system("cp -v #{fname}.#{language} #{fname}") if File.exists?("#{fname}.#{language}") unless language.nil? 
			system("sed -i 's/homecont=[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9]/homecont=#{contsizes.min.to_s}-#{contsizes.max.to_s}/g' #{fname}") if contsizes.max > 0 
			if tgt.size > 15_000_000_000
				system("sed -i 's/swapsize=[0-9][0-9][0-9][0-9]/swapsize=1536 /g' #{fname}")
				system("sed -i 's/blobsize=[0-9][0-9][0-9][0-9]/blobsize=2560 /g' #{fname}")
			elsif tgt.size > 7_000_000_000
				system("sed -i 's/swapsize=[0-9][0-9][0-9][0-9]/swapsize=1024 /g' #{fname}")
				system("sed -i 's/blobsize=[0-9][0-9][0-9][0-9]/blobsize=1536 /g' #{fname}")
			elsif tgt.size > 3_000_000_000
				system("sed -i 's/swapsize=[0-9][0-9][0-9][0-9]/swapsize=512 /g' #{fname}")
				system("sed -i 's/blobsize=[0-9][0-9][0-9][0-9]/blobsize=768 /g' #{fname}")
			end
			system("rm #{fname}") if fname =~ /boot0x80\.cfg$/ 
		}
		system("cp -v /var/run/lesslinux/install_boot/boot/isolinux/{isolinux.cfg,extlinux.conf}") unless File.exists? ("/var/run/lesslinux/install_boot/boot/isolinux/extlinux.conf") 
		# Write syslinux
		system("extlinux --install /var/run/lesslinux/install_boot/boot/isolinux") 
		system("umount /var/run/lesslinux/install_boot")
		system("umount /var/run/lesslinux/install_efi")
		# Write the compat MBR
		sysstr = "dd bs=440 count=1 if=/usr/share/syslinux/gptmbr.bin of=/dev/#{tgt.device} conv=sync"	
		puts sysstr
		system sysstr
		run_command("sync", [ "sync" ], @tl.get_translation("waiting"))
		pgbar.fraction = 1.0
		pgbar.text =  @tl.get_translation("install_finished") 
		# info_dialog( @tl.get_translation("finished_title"), @tl.get_translation("finished_text") ) 
	end

end
