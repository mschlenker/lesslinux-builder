
class BootdiskAssembly 
	
	def initialize (srcdir, builddir, dbh, cfgfile, build_timestamp, branding, overlaydir=nil, full_image=false, grub=true)
		@srcdir =srcdir
		@builddir = builddir
		@dbh = dbh
		@cfgfile = cfgfile
		# @xfile = REXML::Document.new(File.new(cfgfile))
		@tstamp = Time.new.to_i
		@branding = branding
		@build_timestamp = build_timestamp
		@overlaydir = overlaydir
		@full_image = full_image
		@grub = grub
	end
	
	def create_grubx64
		randstr = sprintf("%08d", rand(100_000_000))
		return randstr unless @grub == true
		system("mkdir -p #{@builddir}/stage03/grub.tmp/boot/grub/x86_64-efi")
		[ "lst", "mod"].each { |suff|
			system("cp -v #{@builddir}/stage01/chroot/usr/local/crosstools-amd64/lib/grub/x86_64-efi/*.#{suff} #{@builddir}/stage03/grub.tmp/boot/grub/x86_64-efi/")
		}
		grubcfg = File.new("#{@builddir}/stage03/grub.tmp/boot/grub/grub.cfg", "w")
		grubcfg.write("if ! search --file --set=root /boot/grub/#{randstr}.pt; then\n        search --file --set=root /boot/grub/#{randstr}.cd\nfi\nset prefix=($root)/boot/grub\nif [ -e $prefix/x86_64-efi/grub.cfg ]; then\n        configfile $prefix/x86_64-efi/grub.cfg\nelse\n        configfile $prefix/grub.cfg\nfi\n")
		grubcfg.close
		system("tar -C #{@builddir}/stage03/grub.tmp -cvf #{@builddir}/stage03/grub.tmp/memdisk.tar boot")
		system("mount --bind #{@builddir}/stage03/grub.tmp #{@builddir}/stage01/chroot/tmp")
		# system("chroot #{@builddir}/stage01/chroot /usr/local/crosstools-amd64/bin/amd64-linux-uclibc-grub-mkimage -d /usr/local/crosstools-amd64/lib/grub/x86_64-efi -Ox86_64-efi -o /tmp/grubx64.efi part_gpt part_msdos ntfs ntfscomp fat ext2 btrfs normal chain boot configfile linux multiboot iso9660 udf search search_fs_file search_fs_uuid search_label memdisk tar minicmd ls -m /tmp/memdisk.tar")
		system("chroot #{@builddir}/stage01/chroot /usr/local/crosstools-amd64/bin/grub-mkimage -d /usr/local/crosstools-amd64/lib/grub/x86_64-efi -Ox86_64-efi -o /tmp/grubx64.efi part_gpt part_msdos ntfs ntfscomp fat ext2 btrfs normal chain boot configfile linux multiboot iso9660 udf search search_fs_file search_fs_uuid search_label memdisk tar minicmd ls -m /tmp/memdisk.tar")
		system("umount #{@builddir}/stage01/chroot/tmp")
		return randstr
	end
	
	def create_efiimage(kconfig)
		kcfg = REXML::Document.new(File.new(kconfig))
		# Return if no overlay exists
		return false unless File.directory?(@overlaydir + "/efiimage")
		puts "-> create image for UEFI boot"
		system("mkdir -p #{@builddir}/stage03/cdmaster/boot/efi")
		system("rsync -avHP #{@overlaydir}/efiimage/ #{@builddir}/stage03/efiimage/")
		randstr = create_grubx64
		efi_sha = File.new(@builddir  + "/stage03/efiimage/efi.sha", "w")
		system("mkdir -p #{@builddir}/stage03/efiimage/EFI/BOOT")
		system("rsync -avHP #{@builddir}/stage03/grub.tmp/grubx64.efi #{@builddir}/stage03/efiimage/EFI/BOOT/GRUBX64.EFI") if @grub == true
		kcfg = REXML::Document.new(File.new(kconfig))
		kcfg.elements.each("kernels/kernel") { |k|
			if k.attributes["efi"].to_s == "true"
				kname = k.attributes["short"]
				klong = k.elements["long"].text
				ktarget = "l#{kname}.efi"
				unless k.attributes["efialias"].to_s == ""
					efialias = k.attributes["efialias"].to_s
					ktarget = "EFI/BOOT/#{efialias}.EFI"
				end
				system( "rsync -vP #{@builddir}/stage01/chroot/boot/vmlinuz-#{klong} #{@builddir}/stage03/efiimage/#{ktarget}" )
				system("cat #{@builddir}/stage03/initramfs.gz #{@builddir}/stage03/cpio-#{kname}.gz | gunzip -c | gzip -c > #{@builddir}/stage03/efiimage/i#{kname}.gz")
				ksha = ` sha1sum #{@builddir}/stage03/efiimage/#{ktarget} `.strip.split
				isha =  ` sha1sum #{@builddir}/stage03/efiimage/i#{kname}.gz `.strip.split
				efi_sha.write("#{ksha[0].to_s}  #{ktarget}\n")
				efi_sha.write("#{isha[0].to_s}  i#{kname}.gz\n")
			end
		}
		# Write checksums of other EFI files
		Dir.entries("#{@builddir}/stage03/efiimage/EFI/BOOT").each { |e|
			if e =~ /\.efi$/i 
				esha = ` sha1sum #{@builddir}/stage03/efiimage/EFI/BOOT/#{e} `.strip.split
				efi_sha.write("#{esha[0].to_s}  EFI/BOOT/#{e}\n")
			end
		}
		efi_sha.close 
		system("sync")
		# Calculate size
		imagesize = 0
		IO.popen("du -k #{@builddir}/stage03/efiimage") { |l|
			while l.gets
				puts $_ 
				imagesize = $_.strip.split[0].to_i
				puts imagesize.to_s 
			end
		}
		imagesize = imagesize * 11 / 10240
		system("dd if=/dev/zero bs=1M count=#{imagesize.to_s} of=#{@builddir}/stage03/cdmaster/boot/efi/efi.img")
		freeloop = ` losetup -f `.strip 
		puts "Using loop device: #{freeloop}"
		system("losetup #{freeloop} #{@builddir}/stage03/cdmaster/boot/efi/efi.img")
		system("mkfs.msdos -n LessEfiBoot #{freeloop}")
		system("mkdir #{@builddir}/stage03/efiimage.mnt")
		system("mount -t vfat -o noatime #{freeloop} #{@builddir}/stage03/efiimage.mnt")
		system("rsync -a --inplace #{@builddir}/stage03/efiimage/ #{@builddir}/stage03/efiimage.mnt/")
		system("umount #{freeloop}")
		system("losetup -d #{freeloop}")
		system("mkdir -p #{@builddir}/stage03/cdmaster/boot/grub/x86_64-efi") if @grub == true
		[ "lst", "mod"].each { |suff|
			system("cp -v #{@builddir}/stage01/chroot/usr/local/crosstools-amd64/lib/grub/x86_64-efi/*.#{suff} #{@builddir}/stage03/cdmaster/boot/grub/x86_64-efi/") if @grub == true
		}
		system("touch #{@builddir}/stage03/cdmaster/boot/grub/#{randstr}.cd") 
	end
	
	def create_isoimage (kconfig, write_bootconf)
		root = @branding.root
		squashdirs = [ "bin",  "lib",  "opt", "sbin",  "srv", "usr", "usrbin" ] # , "optkaspersky" ]
		kcfg = REXML::Document.new(File.new(kconfig))
		[ "/stage03/cdmaster/boot/isolinux/", "/stage03/cdmaster/lesslinux/" ].each { |d|
			system( "mkdir -p " + @builddir  + d )
		}
		if @full_image == true
			system("cp -v #{@builddir}/stage01.tar.xz #{@builddir}/stage03/cdmaster/lesslinux/")
		end
		puts "=> building ISO-Image"
		puts "-> Syncing squashfs containers"
		mfile = File.new(@builddir  + "/stage03/cdmaster/lesslinux/mount.txt", "w")
		mods = File.new(@builddir  + "/stage03/cdmaster/lesslinux/modules.txt", "w")
		boot_sha = File.new(@builddir  + "/stage03/cdmaster/lesslinux/boot.sha", "w")
		squash_sha = File.new(@builddir  + "/stage03/cdmaster/lesslinux/squash.sha", "w")
		squashdirs.each { |d|
			if system("test -f " + @builddir + "/stage03/squash/" + d + ".sqs")
				system("mv -v "  + @builddir + "/stage03/squash/" + d + ".sqs " + @builddir  + "/stage03/cdmaster/lesslinux/" )
				# FIXME! FIXME! FIXME!
				if d != "usrbin" ### && d != "optkaspersky"
					mfile.write(d + ".sqs /" + d + "\n")
				elsif d == "usrbin"
					mfile.write("usrbin.sqs /usr/bin\n")
				## elsif d == "optkaspersky"
				## 	mfile.write("optkaspersky.sqs /opt/kaspersky\n")
				end
				# tmphash = Digest::SHA1.hexdigest(File.read(@builddir  + "/stage03/cdmaster/lesslinux/" + d + ".sqs"))
				shaout = ` sha1sum #{@builddir}/stage03/cdmaster/lesslinux/#{d}.sqs `.strip.split 
				squash_sha.write( shaout[0].to_s + "  " + d + ".sqs\n" )
			end
		}
		system("mkdir -p #{@builddir}/stage03/cdmaster/boot/kernel")
		kcfg.elements.each("kernels/kernel") { |k|
			unless k.attributes["efionly"].to_s == "true"
				klong = k.elements["long"].text
				kname = k.attributes["short"]
				puts "-> adding kernel and ramdisk for " + klong
				system( "rsync -vP " + @builddir + "/stage03/cpio-" + kname + ".gz " + @builddir  + "/stage03/cdmaster/boot/kernel/i" + kname + ".img" )
				system( "rsync -vP " + @builddir + "/stage01/chroot/boot/vmlinuz-" + klong + " " + @builddir  + "/stage03/cdmaster/boot/kernel/l" + kname )
				# system( "rsync -vP " + @builddir + "/stage01/chroot/boot/vmlinuz-" + klong + " " + @builddir  + "/stage03/cdmaster/boot/isolinux/linux" )
				system("rsync -avP "  + @builddir + "/stage03/squash/m" + kname + ".sqs " + @builddir  + "/stage03/cdmaster/lesslinux/" ) if File.exists?(@builddir + "/stage03/squash/m" + kname + ".sqs")
				[ "l" + kname, "i" + kname + ".img" ].each { |r|
					tmphash = Digest::SHA1.hexdigest(File.read(@builddir  + "/stage03/cdmaster/boot/kernel/" + r ))
					boot_sha.write( tmphash.to_s + "  " + r  + "\n")
				}
				if system("test -f " + @builddir  + "/stage03/cdmaster/lesslinux/m" + kname + ".sqs")
					tmphash = Digest::SHA1.hexdigest(File.read(@builddir  + "/stage03/cdmaster/lesslinux/m" + kname + ".sqs"))
					squash_sha.write( tmphash.to_s + "  m" + kname + ".sqs\n" )
				end
				mods.write(klong + " m" + kname + ".sqs" + "\n")
			end
		}
		# memtest_exists = system("test -f " + @builddir + "/stage01/chroot/boot/memtest.bin")
		system( "rsync -vP " + @builddir + "/stage01/chroot/boot/memtest.img " + @builddir  + "/stage03/cdmaster/boot/kernel/" ) if File.exist?(@builddir + "/stage01/chroot/boot/memtest.img")
		system( "rsync -vP " + @builddir + "/stage01/chroot/usr/share/memtest/memtest.bin " + @builddir  + "/stage03/cdmaster/boot/kernel/memtest.bzi" ) if File.exist?(@builddir + "/stage01/chroot/usr/share/memtest/memtest.bin")
		mfile.close
		mods.close
		puts "-> adding kernel independent ramdisk"
		system( "rsync -vP " + @builddir + "/stage03/initramfs.gz " + @builddir  + "/stage03/cdmaster/boot/kernel/initram.img" )
		system( "rsync -vP " + @builddir + "/stage03/switch.gz " + @builddir  + "/stage03/cdmaster/boot/kernel/switch.img" )
		# system( "rsync -vP ./bin/initramfs/devs.img " + @builddir  + "/stage03/cdmaster/boot/kernel/devs.img" )
		# FIXME: remove hardcoded overlay!
		# system( "rsync -vP ./bin/initramfs/home.img " + @builddir  + "/stage03/cdmaster/boot/isolinux/home.img" )
		# [ "initram.img", "devs.img" ].each { |r|
		[ "initram.img" ].each { |r|
			tmphash = Digest::SHA1.hexdigest(File.read(@builddir  + "/stage03/cdmaster/boot/kernel/" + r ))
			boot_sha.write( tmphash.to_s + "  " + r + "\n")
		}
		puts "-> adding minimal bootloader config"
		if write_bootconf == true
		[ "syslinux.cfg", "boot/isolinux/isolinux.cfg" ].each { |c|
			isolinux_cfg = File.open(@builddir  + "/stage03/cdmaster/" + c, 'w')
			isolinux_cfg.write("DEFAULT /boot/isolinux/menu.c32\nTIMEOUT 300\n\nPROMPT 0\n\n" + 
				"MENU TITLE COMPUTERBILD Sicher surfen 2009\nMENU TABMSG  \nMENU AUTOBOOT Automatischer Start in # Sekunde{,n}...\n\n")
			entryid = 0
			kcfg.elements.each("kernels/kernel") { |k|
				klong = k.elements["long"].text
				kname = k.attributes["short"]
				
				# Mediumboot!
				isolinux_cfg.write("LABEL " + entryid.to_s + "\nMENU LABEL Komplettstart\n") #  + klong + "\nMENU DEFAULT\n" )
				isolinux_cfg.write("KERNEL /boot/isolinux/l" + kname + "\n")
				# security=smack pax_softmode=1" )
				isolinux_cfg.write("APPEND initrd=/boot/isolinux/devs.img,/boot/isolinux/initram.img,/boot/isolinux/i" + kname + 
					".img ramdisk_size=100000 vga=788 ultraquiet=1 security=smack skipcheck=1" +  
					" quiet lang=de " )
				if c == "syslinux.cfg"
					#isolinux_cfg.write(" skipservices=|luksmount|mountcdrom|loadata| ")
					isolinux_cfg.write(" toram=999999999 skipservices=|mountcdrom|loadata|installer|xconfgui|roothash| ")
				else
					#isolinux_cfg.write(" skipservices=|luksmount|mountumass| ")
					isolinux_cfg.write(" toram=800000 ejectonumass=1 skipservices=|installer|xconfgui|roothash| ")
				end
				isolinux_cfg.write(" hwid=unknown \n")
				isolinux_cfg.write("TEXT HELP\n")
				isolinux_cfg.write("  Mit dieser Auswahl laesst sich die Darstellung optimal an Ihren Monitor\n" + 
						   "  anpassen. Ausserdem haben Sie Zugriff auf Ihre Laufwerke, etwa um Dateien\n" + 
						   "  aus dem Internet zu speichern.\nENDTEXT\n\n\n")
				entryid += 1
				
				# Fastboot!
				isolinux_cfg.write("LABEL " + entryid.to_s + "\nMENU LABEL Schnellstart\n") #  + klong + "\n" )
				isolinux_cfg.write("KERNEL /boot/isolinux/l" + kname + "\n")
				# security=smack pax_softmode=1" )
				isolinux_cfg.write("APPEND initrd=/boot/isolinux/devs.img,/boot/isolinux/initram.img,/boot/isolinux/i" + kname + 
					".img ramdisk_size=100000 vga=788 ultraquiet=1 security=smack skipcheck=1" +  
					" quiet lang=de" )
				if c == "syslinux.cfg"
					#isolinux_cfg.write(" skipservices=|luksmount|mountcdrom|loadata| ")
					isolinux_cfg.write("  toram=999999999 skipservices=|mountcdrom|loadata|hwproto|xconfgui|installer|runtimeconf|roothash| ")
				else
					#isolinux_cfg.write(" skipservices=|luksmount|mountumass| ")
					isolinux_cfg.write(" toram=999999999 ejectonumass=1 skipservices=|hwproto|xconfgui|installer|runtimeconf|roothash| ")
				end
				isolinux_cfg.write(" hwid=unknown \n")
				isolinux_cfg.write("TEXT HELP\n")
				isolinux_cfg.write("  Moechten Sie einfach nur im Internet surfen, waehlen Sie diese Option.\n" + 
						   "  Die Surf-CD startet dann mit einer Standard-Einstellung fuer alle\n" + 
						   "  Monitore und ohne Laufwerkszugriff.\nENDTEXT\n\n\n")
				entryid += 1
				
				# Fastboot with res
				[ "800x600", "1024x600", "1024x768", "1280x800", "1280x1024", "1440x900", "1680x1050" ].each { |res|
					isolinux_cfg.write("LABEL " + entryid.to_s + "\nMENU HIDE\nMENU LABEL Fastboot " + res + "\nMENU INDENT 3\n" )
					isolinux_cfg.write("KERNEL /boot/isolinux/l" + kname + "\n")
					# security=smack pax_softmode=1" )
					isolinux_cfg.write("APPEND initrd=/boot/isolinux/devs.img,/boot/isolinux/initram.img,/boot/isolinux/i" + kname + 
						".img ramdisk_size=100000 vga=788 ultraquiet=1 security=smack skipcheck=1" +  
						" quiet lang=de toram=999999999 xmode=" + res)
					if c == "syslinux.cfg"
						#isolinux_cfg.write(" skipservices=|luksmount|mountcdrom|loadata| ")
						isolinux_cfg.write(" skipservices=|mountcdrom|loadata|hwproto|xconfgui|installer|runtimeconf|roothash| ")
					else
						#isolinux_cfg.write(" skipservices=|luksmount|mountumass| ")
						isolinux_cfg.write(" ejectonumass=1 skipservices=|hwproto|xconfgui|installer|runtimeconf|roothash| ")
					end
					isolinux_cfg.write(" hwid=unknown \n\n\n")
					entryid += 1
				}
				
				# Installation!
				isolinux_cfg.write("LABEL " + entryid.to_s + "\nMENU LABEL Installation\n" ) # + klong + "\n" )
				isolinux_cfg.write("MENU HIDE\n") if c == "syslinux.cfg"
				isolinux_cfg.write("KERNEL /boot/isolinux/l" + kname + "\n")
				# security=smack pax_softmode=1" )
				isolinux_cfg.write("APPEND initrd=/boot/isolinux/devs.img,/boot/isolinux/initram.img,/boot/isolinux/i" + kname + 
					".img ramdisk_size=100000 vga=788 ultraquiet=1 security=smack skipcheck=1" +  
					" quiet lang=de toram=9999999999 " )
				if c == "syslinux.cfg"
					#isolinux_cfg.write(" skipservices=|luksmount|mountcdrom|loadata| ")
					isolinux_cfg.write(" skipservices=|mountcdrom|loadata|xconfgui|dbus|wicd|runtimeconf|alsaprepare|ffprep|roothash| ")
				else
					#isolinux_cfg.write(" skipservices=|luksmount|mountumass| ")
					isolinux_cfg.write(" skipservices=|mountumass|xconfgui|dbus|wicd|runtimeconf|alsaprepare|ffprep|roothash| ")
				end
				isolinux_cfg.write(" hwid=unknown \n")
				isolinux_cfg.write("TEXT HELP\n")
				isolinux_cfg.write("  Installieren Sie die Surf-CD auf einem USB-Laufwerk (Speicherstift,\n" + 
						   "  Speicherkarte, Festplatte). Ihre Einstellungen, E-Mails und Dateien\n" + 
						   "  werden dann in einem Datentresor sicher verwahrt.\nENDTEXT\n\n\n")
				entryid += 1
			}
			#if memtest_exists == true
			#	isolinux_cfg.write("LABEL " + entryid.to_s + "\nMENU LABEL Speichertest\n" ) # + klong + "\n" )
			#	isolinux_cfg.write("KERNEL /boot/isolinux/memtest.bin\n")
			#	isolinux_cfg.write("TEXT HELP\n")
			#	isolinux_cfg.write("  Testen Sie Ihren Arbeitsspeicher auf Beschaedigungen.\nENDTEXT\n\n\n")
			#	entryid += 1
			#end
			isolinux_cfg.close
		}
		end
		boot_sha.close
		squash_sha.close
		puts "-> adding bootloader"
		[ "menu.c32", "vesamenu.c32", "isolinux.bin", "ifcpu.c32", "ifcpu64.c32", "reboot.c32", "chain.c32", "ldlinux.c32", "libutil.c32", "libmenu.c32", "libcom32.c32", "liblua.c32", "libgpl.c32" ].each { |f|
			# system("rsync -vP ./bin/syslinux/" + f  + ".3.73 " + @builddir  + "/stage03/cdmaster/boot/isolinux/" + f)
			system("install -m 0755 " + @builddir  + "/stage01/chroot/usr/share/syslinux/" + f + " " + @builddir  + "/stage03/cdmaster/boot/isolinux/")
		}
		create_efiimage(kconfig)
		puts "-> mastering ISO"
		oldpwd = Dir.getwd
		Dir.chdir( @builddir  + "/stage03/cdmaster" )
		system("zip -r ../" + root.elements["brandshort"].text.strip + "-" + root.elements["updater/buildidentifier"].text.strip + @build_timestamp + "-boot.zip boot")
		Dir.chdir( @builddir  + "/stage03" )
		if File.exist?("#{@builddir}/stage03/cdmaster/boot/efi/efi.img")
			isomoddate = @build_timestamp.gsub("-", "") 
			xcomm = "#{@builddir}/stage01/chroot/usr/compat.static/bin/xorriso -as mkisofs " +
				" -joliet -graft-points " + 
				" -c boot/isolinux/boot.cat " + 
				" -b boot/isolinux/isolinux.bin " + 
				" -no-emul-boot -boot-info-table -boot-load-size 4 " +
				" -isohybrid-mbr #{@builddir}/stage01/chroot/usr/share/syslinux/isohdpfx.bin " +
				" -eltorito-alt-boot " + 
				" -e boot/efi/efi.img " + 
				" -no-emul-boot " + 
				" -isohybrid-gpt-basdat --modification-date=#{isomoddate}00 -V " + 
				root.elements["brandshort"].text.strip.upcase.gsub("-", "_") + 
				" -o " + root.elements["brandshort"].text.strip + "-" +
				root.elements["updater/buildidentifier"].text.strip + 
				@build_timestamp + ".iso " + 
				" -r cdmaster --sort-weight 0 / --sort-weight 1 /boot --sort-weight 2 /boot/efi --sort-weight 3 /boot/kernel --sort-weight 4 /boot/grub --sort-weight 5 /boot/isolinux --sort-weight 6 /boot/isolinux/isolinux.bin " 
			puts xcomm
			system xcomm
			xcomm = "#{@builddir}/stage01/chroot/usr/compat.static/bin/xorriso -as mkisofs " +
				" -joliet -graft-points " + 
				" -c boot/isolinux/boot.cat " + 
				" -b boot/isolinux/isolinux.bin " + 
				" -no-emul-boot -boot-info-table -boot-load-size 4 " +
				" -isohybrid-mbr #{@builddir}/stage01/chroot/usr/share/syslinux/isohdpfx.bin " +
				" -eltorito-alt-boot " + 
				" -e boot/efi/efi.img " + 
				" -no-emul-boot " + 
				" -isohybrid-gpt-basdat --modification-date=#{isomoddate}01 -V " + 
				root.elements["brandshort"].text.strip.upcase.gsub("-", "_") + 
				" -o " + root.elements["brandshort"].text.strip + "-" +
				root.elements["updater/buildidentifier"].text.strip + 
				@build_timestamp + "-bootonly.iso " + 
				" -r /boot=./cdmaster/boot --sort-weight 2 /boot/efi --sort-weight 3 /boot/kernel --sort-weight 4 /boot/grub --sort-weight 5 /boot/isolinux --sort-weight 6 /boot/isolinux/isolinux.bin " 
			puts xcomm
			system xcomm
		else
			isomoddate = @build_timestamp.gsub("-", "") 
			xcomm = "#{@builddir}/stage01/chroot/usr/compat.static/bin/xorriso -as mkisofs " +
				" -joliet -graft-points " + 
				" -c boot/isolinux/boot.cat " + 
				" -b boot/isolinux/isolinux.bin " + 
				" -no-emul-boot -boot-info-table -boot-load-size 4 " +
				" -isohybrid-mbr #{@builddir}/stage01/chroot/usr/share/syslinux/isohdpfx.bin " +
				" --modification-date=#{isomoddate}00 -V " + 
				root.elements["brandshort"].text.strip.upcase.gsub("-", "_") + 
				" -o " + root.elements["brandshort"].text.strip + "-" +
				root.elements["updater/buildidentifier"].text.strip + 
				@build_timestamp + ".iso " + 
				" -r cdmaster --sort-weight 0 / --sort-weight 1 /boot --sort-weight 3 /boot/kernel --sort-weight 4 /boot/grub --sort-weight 5 /boot/isolinux --sort-weight 6 /boot/isolinux/isolinux.bin " 
			puts xcomm
			system xcomm
			xcomm = "#{@builddir}/stage01/chroot/usr/compat.static/bin/xorriso -as mkisofs " +
				" -joliet -graft-points " + 
				" -c boot/isolinux/boot.cat " + 
				" -b boot/isolinux/isolinux.bin " + 
				" -no-emul-boot -boot-info-table -boot-load-size 4 " +
				" -isohybrid-mbr #{@builddir}/stage01/chroot/usr/share/syslinux/isohdpfx.bin " +
				" --modification-date=#{isomoddate}01 -V " + 
				root.elements["brandshort"].text.strip.upcase.gsub("-", "_") + 
				" -o " + root.elements["brandshort"].text.strip + "-" +
				root.elements["updater/buildidentifier"].text.strip + 
				@build_timestamp + "-bootonly.iso " + 
				" -r /boot=./cdmaster/boot --sort-weight 3 /boot/kernel --sort-weight 4 /boot/grub --sort-weight 5 /boot/isolinux --sort-weight 6 /boot/isolinux/isolinux.bin " 
			puts xcomm
			system xcomm
		end
		
		#if system("which perl") && system("test -f " + @builddir  + "/stage01/chroot/usr/share/syslinux/isohybrid.pl") 
		#	system("perl " + @builddir  + "/stage01/chroot/usr/share/syslinux/isohybrid.pl " +  
		#		@builddir  + "/stage03/" + root.elements["brandshort"].text.strip + "-" + 
		#		root.elements["updater/buildidentifier"].text.strip + 
		#		@build_timestamp + ".iso")
		#else
		#	$stderr.puts "+++> isohybrid not found, resulting ISO will not be bootable from USB stick!"
		#end
		Dir.chdir(oldpwd)
	end
	
	# def create_usbimage
		# create a GPT partitioned image with three partitions - ISO, bios compat boot and UEFI boot
		# Get size of ISO image, round to next MB
		# Get size of /boot/isolinux, add three MB
		# Get size of UEFI boot partition 
		# Create a disk image of appropriate size
		# Create three partitions - first partition starts at 1MB offset
		# Set proper flags - boot and legacy_boot
		# Map partitions - kpartx and device mapper required
		# dd ISO and UEFI boot partition to their appropriate partitions
		# copy boot files
		# create extlinux loader
		# write compat MBR
	# end
	
	def BootdiskAssembly.sync_overlay(builddir, overlaydir)
		system("rsync -avHP '" + overlaydir + "/' " + builddir  + "/stage03/cdmaster/")
	end
	
	def BootdiskAssembly.copy_version(builddir)
		system("mkdir -p " + builddir + "/stage03/cdmaster/lesslinux")
		system("cp -v " + builddir + "/stage03/initramfs/etc/lesslinux/updater/version.txt " + builddir + "/stage03/cdmaster/lesslinux/version.txt")
		# FIMXE: It should be possible to  tell by CLI switch whether ISOhybrid should be stretched or not!
		# system("cp -v " + builddir + "/stage03/initramfs/etc/lesslinux/updater/version.txt " + builddir + "/stage03/cdmaster/lesslinux/stretch.me")
	end
	
end