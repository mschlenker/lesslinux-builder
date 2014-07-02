
class ThirdStage < AnyStage
	
	def calculate_deps
		puts @pkg_name.to_s + " " + @pkg_version.to_s
		# resset = @dbh.query("SELECT fname FROM llfiles WHERE stage='stage02' " + 
		#	" AND pkg_name='" + @dbh.escape_string(@pkg_name) + "' " + 
		#	" AND pkg_version='" + @dbh.escape_string(@pkg_version) + "' " + 
		#	" AND ( cleaned_type LIKE 'linux_x86_exe_%' OR cleaned_type LIKE 'linux_x86_so_%' ) ")
		sqlite_resset = @sqlite.query("SELECT fname FROM llfiles WHERE stage='stage02' " + 
			" AND pkg_name=? AND pkg_version=? " + 
			" AND cleaned_type NOT NULL AND " + 
			" ( cleaned_type LIKE 'linux_x86_exe_%' OR cleaned_type LIKE 'linux_x86_so_%' ) ",
			[ SQLite3::Database.quote(@pkg_name), SQLite3::Database.quote(@pkg_version) ] )
		binset = Array.new
		# All objects provided
		# resset.each { |i| binset.push(i[0].strip) }
		sqlite_resset.each { |i| binset.push(i[0].strip) }
		# All objects needed
		depset = Array.new
		binset.each { |b|
			IO.popen("chroot " +   @builddir + "/stage01/chroot /usr/bin/ldd " + b ) { |f|
				while f.gets
					depset.push($_.split[0])
				end
			}
		}
		depset.uniq!
		depset.delete("/lib/ld-linux.so.2")
		depset.delete("libc.so.6")
		depset.delete("linux-gate.so.1")
		depset.delete("statically")
		resdeps = depset.clone
		depset.each { |d|
			binset.each { |b|
				unless b.index(d).nil?
					resdeps.delete(d)
				end
			}
		}
		return resdeps
	end

	def makedirs
		@xfile.elements.each("llpackages/dirs/dir") { |i|
			system("install -m " + i.attributes["mode"] + " -d " + @builddir + "/stage03/initramfs" + i.text )
		}
	end

	def touchfiles
		@xfile.elements.each("llpackages/files/file") { |i|
			File.new(@builddir + "/stage03/initramfs" + i.text , 'w').close
			File.chmod(i.attributes["mode"].to_i(8), @builddir + "/stage03/initramfs" + i.text )
			File.chown(i.attributes["owner"].to_i, i.attributes["group"].to_i, @builddir + "/stage03/initramfs" + i.text )
		}
		@xfile.elements.each("llpackages/links/softlink") { |i|
			system("ln -sv " + i.attributes["target"] + " " + @builddir + "/stage03/initramfs/" + i.text  )
		}
	end
	
	def scriptgen
		@xfile.elements.each("llpackages/scripts/scriptdata") { |i|
			outfile = File.open(@builddir + "/stage03/initramfs" + i.attributes["location"], 'w')
			outfile.write(i.cdatas[0])
			outfile.write("\n")
			outfile.close
			File.chmod(i.attributes["mode"].to_i(8), 
				@builddir + "/stage03/initramfs" + i.attributes["location"])
			File.chown(i.attributes["owner"].to_i, 
				i.attributes["group"].to_i, 
				@builddir + "/stage03/initramfs" + i.attributes["location"])
		}
		@xfile.elements.each("llpackages/scripts/modlist") { |i|
			provides = i.attributes["provides"]
			hwenv = i.attributes["hwenv"]
			outfile = File.open(@builddir + "/stage03/initramfs/etc/rc.confd/" + provides + "." + hwenv + ".modules" , 'w')
			i.elements.each("module") { |j| outfile.write(j.text + "\n") }
			outfile.close
		}
	end
	
	def install
		if File.exists?(@builddir + "/stage03/build/" + @pkg_name + "-" + @pkg_version + "/install.success") 
			puts "-> previous installation of " + @pkg_name + " successful"
		else
			puts "-> installing " + @pkg_name + " " + @pkg_version 
			### Dir.chdir(@builddir + "/stage03/build/" + @pkg_name + "-" + @pkg_version)
			# Script to enter chroot and trigger the installscript
			iscript = File.open(@builddir + "/stage03/build/" + @pkg_name + "-" + @pkg_version + "/install.sh", 'w')
			iscript.write("#!/bin/bash\n")
			iscript.write("cd " + @builddir + "/stage03/build/" + @pkg_name + "-" + @pkg_version +  "\n")
			iscript.write("INITRAMFS='" + @builddir + "/stage03/initramfs'; export INITRAMFS\n")
			iscript.write("SQUASHFS='" + @builddir + "/stage03/squash'; export SQUASHFS\n")
			iscript.write("CHROOT='" + @builddir + "/stage01/chroot'; export CHROOT\n")
			iscript.write(". common_vars\n")
			begin
				iscript.write(@xfile.elements["llpackages/package/install"].cdatas[0])
			rescue
				iscript.write("# Nothing to do here!\n")
			end
			iscript.write("\n\n")
			iscript.close
			File.chmod(0755, @builddir + "/stage03/build/" + @pkg_name + "-" + @pkg_version +  "/install.sh")
			retval = system(@builddir + "/stage03/build/" + @pkg_name + "-" + @pkg_version +  "/install.sh")
			if (retval == true)
				File.open(@builddir + "/stage03/build/" + @pkg_name + "-" + @pkg_version +  "/install.success", "w") { |f| 
					f.write(Time.now.to_i.to_s + "\n")
				}
			end
		end
	end
	
	def do_tar (target_dir, tar_files)
		system("tar -C " + @builddir + "/stage01/chroot/ -c " + tar_files.join(" ") + " -f - | tar -C " + target_dir + " -xvf - ") if tar_files.size > 0
	end
	
	def do_strip (strip_files)
		system("strip " + strip_files.join(" "))
	end
	
	# Install prepared files from the file list generated in the last step
	
	def pkg_install ( subpkgs, langs, skipfiles, skipdirs=Array.new)
		# Currently just check for automatically generated file from the last build
		# FIXME: Add prepared/modified versions later
		# FIXME: Add possibility to skip later
		pfile = nil
		searchdir = "./"
		unless @nonfree.nil?
			searchdir = "#{@nonfree}/" 
		end
		if File.exists?(searchdir + "scripts/pkg_content/" + @pkg_name + "-" + pkg_version + ".xml" )
			if @unstable == true && File.exists?(searchdir + "scripts/pkg_content.unstable/" + @pkg_name + "-" + pkg_version + ".xml" )
				pfile = REXML::Document.new(File.new(searchdir + "scripts/pkg_content.unstable/" + @pkg_name + "-" + pkg_version + ".xml", "r"))
			else
				pfile = REXML::Document.new(File.new(searchdir + "scripts/pkg_content/" + @pkg_name + "-" + pkg_version + ".xml", "r"))
			end
		elsif File.exists?("scripts/pkg_content/" + @pkg_name + "-" + pkg_version + ".xml" )
			if @unstable == true && File.exists?("scripts/pkg_content.unstable/" + @pkg_name + "-" + pkg_version + ".xml" )
				pfile = REXML::Document.new(File.new("scripts/pkg_content.unstable/" + @pkg_name + "-" + pkg_version + ".xml", "r"))
			else
				pfile = REXML::Document.new(File.new("scripts/pkg_content/" + @pkg_name + "-" + pkg_version + ".xml", "r"))
			end
		elsif File.exists?(@builddir + "/stage02/build/" + @pkg_name + "-" + pkg_version + ".xml" ) 
			# $stderr.puts("***> be careful: no exactly matching pkg_list found for " + @pkg_name + "-" + pkg_version) 
			puts sprintf("%015.4f", Time.now.to_f) + " warn   > No exactly matching pkg_content found for " + @pkg_name + "-" + pkg_version 
			$stdout.flush
			pfile = REXML::Document.new(File.new(@builddir + "/stage02/build/" + @pkg_name + "-" + pkg_version + ".xml" , "r"))
		elsif xfile.elements["llpackages/package"].attributes["allowfail"].nil?
			puts "=> trying to install nonexistent package! " + @pkg_name + "-" + pkg_version
			puts "   You might want to add the attribute 'allowfail=yes'!"
			raise "StageThreeInstallError" 
		else
			return 0
		end
		installed_files = 0
		initramfsdirs = ["etc", "static",  "var" ]
		ignoredirs = [ "boot",  "dev", "home", "llbuild", "media", "mnt", "proc", "root", "sys", "tmp", "tools" ]
		squashdirs = [ "bin",  "lib",  "opt", "sbin",  "srv", "usr" ]
		files_to_strip = Array.new
		tarfiles_squash = Array.new
		tarfiles_initrd = Array.new
		pfile.elements.each("pkgdesc/subpackage") { |s|
			if subpkgs.include?(s.attributes["name"].strip)
				s.elements.each("file") { |l|
					path = l.attributes["path"].strip
					initramfsdirs.each{ |i|
						if l.attributes["path"].index(i) == 1
							# system("tar -C " + @builddir + "/stage01/chroot/ -c '" + path.sub(/^\//, '') + 
							# "' -f - | tar -C " + @builddir + "/stage03/initramfs/ -xvf - ")
							tarfiles_initrd.push("'" + path.sub(/^\//, '') + "'") unless skipfiles.include?(path)
							# system("strip " + @builddir + "/stage03/initramfs/" + path.sub(/^\//, '')) if @strip == true
							files_to_strip.push("'" + @builddir + "/stage03/initramfs/" + path.sub(/^\//, '') + "'") if @strip == true
							installed_files += 1
							if tarfiles_initrd.size > 50
								do_tar(@builddir + "/stage03/initramfs/", tarfiles_initrd)
								tarfiles_initrd = Array.new
							end
							if files_to_strip.size > 50
								do_tar(@builddir + "/stage03/initramfs/", tarfiles_initrd)
								tarfiles_initrd = Array.new
								do_strip(files_to_strip)
								files_to_strip = Array.new
							end
							
						end
					}
					squashdirs.each{ |i|
						if l.attributes["path"].index(i) == 1
							# system("tar -C " + @builddir + "/stage01/chroot/ -c '" + path.sub(/^\//, '') + 
							# "' -f - | tar -C " + @builddir + "/stage03/squash/ -xvf - ")
							tarfiles_squash.push("'" + path.sub(/^\//, '') + "'") unless skipfiles.include?(path)
							# system("strip " + @builddir + "/stage03/squash/" + path.sub(/^\//, ''))  if @strip == true
							files_to_strip.push("'" + @builddir + "/stage03/squash/" + path.sub(/^\//, '') + "'") if @strip == true
							installed_files += 1
							if tarfiles_squash.size > 50
								do_tar(@builddir + "/stage03/squash/", tarfiles_squash)
								tarfiles_squash = Array.new
							end
							if files_to_strip.size > 50
								do_tar(@builddir + "/stage03/squash/", tarfiles_squash)
								tarfiles_squash = Array.new
								do_strip(files_to_strip)
								files_to_strip = Array.new
							end
						end
					}
				}
			end
		}
		if tarfiles_squash.size > 0
			do_tar(@builddir + "/stage03/squash/", tarfiles_squash)
		end
		if tarfiles_initrd.size > 0
			do_tar(@builddir + "/stage03/initramfs/", tarfiles_initrd)
		end
		pfile.elements.each("pkgdesc/subpackage") { |s|
			s.elements.each("directory") { |d|
				initramfsdirs.each{ |i|
					if d.attributes["path"].strip.index(i) == 1
						fmode = "40755"
						fmode = d.attributes["mode"] unless d.attributes["mode"].nil?
						unless File.directory?(@builddir + "/stage03/initramfs" + d.attributes["path"].strip)
						# system("test -d '"+ @builddir + "/stage03/initramfs" + d.attributes["path"].strip  + "'")
							puts "-> create nonexistent directory " + d.attributes["path"].strip
							system("mkdir -p -m " + fmode.slice(-3 .. -1) + " '" +
								@builddir + "/stage03/initramfs" + d.attributes["path"].strip  + "'")
						end
					end
				}
				squashdirs.each{ |i|
					if d.attributes["path"].strip.index(i) == 1
						fmode = "40755"
						fmode = d.attributes["mode"] unless d.attributes["mode"].nil?
						unless File.directory?(@builddir + "/stage03/squash" + d.attributes["path"].strip) 
						# system("test -d '"+ @builddir + "/stage03/squash" + d.attributes["path"].strip  + "'")
							puts "-> create nonexistent directory " + d.attributes["path"].strip
							system("mkdir -p -m " + fmode.slice(-3 .. -1) + " '" + 
								@builddir + "/stage03/squash" + d.attributes["path"].strip  + "'")
						end
					end
				}
			}
		}
		if files_to_strip.size > 0 
			# system("strip " + files_to_strip.join(" "))
			do_strip(files_to_strip)
		end
		if installed_files < 1 && @xfile.elements["llpackages/package"].attributes["allowfail"].nil?
			puts "=> installation did not result in new files!"
			puts "   either check the pkg-file " + @pkg_name + "-" + pkg_version + ".xml"
			puts "   or remove the package from being included in stage03!"
			puts "   You might want to add the attribute 'allowfail=yes'!"
			raise "StageThreeInstallError"
		end
	end

	def assemble_modules (kconfig, modmodel)
		kcfg = REXML::Document.new(File.new(kconfig))
		kcfg.elements.each("kernels/kernel") { |k|
			klong = k.elements["long"].text
			kname = k.attributes["short"]
			puts "=> adding modules for " + klong
			[ "/", "/static", "/static/modules" ].each { |d|
				begin
					Dir.mkdir( @builddir + "/stage03/cpio-" + kname + d )
				rescue
					puts "->dir seems to exist"
				end
			}
			@xfile.elements.each("llpackages/scripts/modlist") { |i|
				if @modmodel == "old" || i.attributes["provides"].to_s.strip == "systemfs"
					i.elements.each("module") { |j|
						IO.popen("find " + @builddir + "/stage01/chroot/lib/modules/" +  klong + " -type f -name " + j.text + ".ko"  ) { |f|
							while f.gets
								system("rsync -vP " + $_.strip + " " + @builddir + "/stage03/cpio-" + kname + "/static/modules/")
							end
						}
					}
				end
			}
		}
		# raise "DebugBreakPoint"
	end

	def ThirdStage.create_softlinks_ng(builddir, dbh)
		expdir = File.expand_path(builddir + "/stage01/chroot")
		reprexp = Regexp.new('^' + expdir)
		raw_links = Array.new
		all_links = Array.new
		all_targets = Array.new
		links_with_targets = Hash.new
		IO.popen("find " + expdir + " -xdev -type l") { |f|
			while f.gets
				raw_links.push $_.strip
			end
		}
		raw_links.each { |l|
				link = l
				# targ = ` ls -la "#{link}"`.split(" -> ")[1]
				targ = File.readlink l 
				abstarget = nil
				# Find out if link is relative or absolute
				if targ =~ /^\//
					puts "ABS " + link + " -> " + targ 
					abstarget = expdir + targ
					puts "    " + abstarget
				else
					puts "REL " + link + " -> " + targ
					linkdir = File.dirname(link)
					abstarget = File.expand_path(linkdir + "/" + targ)
					puts "    " + abstarget
				end
				[ "bin",  "lib",  "opt", "sbin",  "srv", "usr", "static" ].each { |d|
					if link.strip.sub(reprexp, '').index(d) == 1
						all_links.push(link.strip.sub(reprexp, ''))
						all_targets.push(abstarget.strip.sub(reprexp, ''))
						links_with_targets[link.strip.sub(reprexp, '')] = abstarget.strip.sub(reprexp, '')
					end
				}
		}
		links_to_links = all_targets & all_links
		links_to_others = all_links - all_targets
		links_to_create = Array.new
		links_to_others.each { |l|
			if File.exist?(builddir + "/stage03/squash" + links_with_targets[l]) || 
				File.symlink?(builddir + "/stage03/squash" + links_with_targets[l]) ||
				File.chardev?(builddir + "/stage03/squash" + links_with_targets[l]) ||
				File.blockdev?(builddir + "/stage03/squash" + links_with_targets[l])
				links_to_create.push("'" + l.sub(/^\//, '') + "'")
				# system("tar -C " + builddir + "/stage01/chroot -cvf - \"" + l.sub(/^\//, '') + "\" | tar -C " + builddir + "/stage03/squash -xf - ")
				if links_to_create.size > 50
					system("tar -C " + builddir + "/stage01/chroot -cvf - " + links_to_create.join(" ") + " | tar -C " + builddir + "/stage03/squash -xf - ")
					links_to_create = Array.new
				end
			end
		}
		if links_to_create.size > 0
			system("tar -C " + builddir + "/stage01/chroot -cvf - " + links_to_create.join(" ") + " | tar -C " + builddir + "/stage03/squash -xf - ")
		end
		5.times {
			links_to_links.each { |l|
				if File.symlink?(builddir + "/stage03/squash" + links_with_targets[l]) ||
					system("tar -C " + builddir + "/stage01/chroot -cvf - \"" + l.sub(/^\//, '') + "\" | tar -C " + builddir + "/stage03/squash -xf - ")
				end
			}
		}
		# at last find all Softlinks in busybox' /bin and /sbin
		["/bin/", "/sbin/"].each { |d|
			#puts("LC_ALL=C find " + builddir + "/stage03/initramfs/static" + d + " -type l " + 
			#" -exec file -F ':::::' {} \\\; | grep busybox | awk -F '::::: ' '{print \$1}'")
			IO.popen("find " + builddir + "/stage03/initramfs/static" + d + " -type l " + 
			" -exec file -F ':::::' {} \\\; ") { |f|
				while f.gets 
					pin = $_.strip
					if pin["busybox"]
						softlink = pin.split('::::: ')[0].sub(builddir + "/stage03/initramfs/static" + d, '')
						# Check if an according entry exists in /bin, /sbin, /usr/bin, /usr/sbin, /usr/local/bin, /usr/local/sbin, 
						newloc = nil
						[ "/bin/", "/sbin/", "/usr/bin/", "/usr/sbin/", "/usr/local/bin/", "/usr/local/sbin/" ].each { |t|
							if system("test -e " + builddir + "/stage03/squash" + t + softlink) || 
									system("test -f " + builddir + "/stage03/squash" + t + softlink)
								newloc = t + softlink
							end
						}
						if newloc.nil?
							system("ln -s /static/bin/busybox " + builddir + "/stage03/squash" + d + softlink)
						end
					end
				end
			}
		}
	end
	
	def ThirdStage.create_softlinks (builddir, dbh )
		# Find all links
		# all_links = dbh.query("SELECT DISTINCT fname FROM llfiles WHERE ftype='l' AND fname NOT LIKE '/tools/%' ORDER BY fname ASC" )
		expdir = File.expand_path(builddir + "/stage01/chroot")
			reprexp = Regexp.new('^' + expdir)
		all_softlinks = Array.new
		IO.popen("find " + expdir + " -xdev -type l") { |f|
			while f.gets
				[ "bin",  "lib",  "opt", "sbin",  "srv", "usr" ].each { |d|
					lnk = $_.strip.sub(reprexp, '')
					if lnk.index(d) == 1
						all_softlinks.push $_.strip.sub(reprexp, '')
					end
				}
			end
		}
		# 3 times to guarantee the maximum depth of chained links
		3.times {
			all_softlinks.each { |l|
				unless system("ls -la '"+ builddir + "/stage03/squash" + l.to_s + "' > /dev/null 2>&1 " )
					# find out if parent directory exists
					parentdir = nil
					IO.popen("dirname '" + l.to_s + "' ") { |f|
						while f.gets
							aux_par = $_
							unless aux_par.nil?
								parentdir = aux_par.strip
								puts parentdir
							end
						end
					}
					# find target of softlink
					linktarget = nil
					IO.popen(" ls -la '" + builddir + "/stage01/chroot" + l.to_s + "' ") { |f|
						while f.gets
							aux_tar = $_
							begin
								linktarget = aux_tar.split(' -> ')[1].strip
							rescue 
								puts '=> ls failed: ' +  aux_tar.to_s
							end
						end
					}
					# link if softlink is not vanished
					unless linktarget.nil?
						# create parent directory if necessary
						unless parentdir.nil? 
							system("mkdir -pv '"+ builddir + "/stage03/squash" + parentdir + "' " )
						end
						system("ln -sv '" +   linktarget + "' '" + builddir + "/stage03/squash" + l.to_s + "' ")
					end
				end
			}
		}	
		# first find all Softlinks in busybox' /bin and /sbin
		["/bin/", "/sbin/"].each { |d|
			#puts("LC_ALL=C find " + builddir + "/stage03/initramfs/static" + d + " -type l " + 
			#" -exec file -F ':::::' {} \\\; | grep busybox | awk -F '::::: ' '{print \$1}'")
			IO.popen("LC_ALL=C find " + builddir + "/stage03/initramfs/static" + d + " -type l " + 
			" -exec file -F ':::::' {} \\\; ") { |f|
				while f.gets 
					pin = $_.strip
					if pin["busybox"]
						softlink = pin.split('::::: ')[0].sub(builddir + "/stage03/initramfs/static" + d, '')
						# Check if an according entry exists in /bin, /sbin, /usr/bin, /usr/sbin, /usr/local/bin, /usr/local/sbin, 
						newloc = nil
						[ "/bin/", "/sbin/", "/usr/bin/", "/usr/sbin/", "/usr/local/bin/", "/usr/local/sbin/" ].each { |t|
							if system("test -e " + builddir + "/stage03/squash" + t + softlink) || 
									system("test -f " + builddir + "/stage03/squash" + t + softlink)
								newloc = t + softlink
							end
						}
						if newloc.nil?
							system("ln -s /static/bin/busybox " + builddir + "/stage03/squash" + d + softlink)
						end
					end
				end
			}
		}
	end
	
	def ThirdStage.copy_firmware (builddir)
		system("tar -C " + builddir + "/stage01/chroot/ -c 'lib/firmware' -f - | tar -C " + builddir + "/stage03/squash/ -xvf - ")
		system("mkdir " + builddir + "/stage03/initramfs/")
		# system("tar -C " + builddir + "/stage01/chroot/ -c 'lib/firmware' -f - | tar -C " + builddir + "/stage03/initramfs/ -xvf - ")
	end
	
	def ThirdStage.create_squashfs (builddir, kconfig)
		mksquashfs = "mksquashfs"
		mksquashfs = "mksquashfs4" if system("which mksquashfs4")
		squashdirs = [ "bin",  "lib",  "opt", "sbin",  "srv", "usr", "usrbin", "firmware" ] # , "optkaspersky" ]
		# kconfig = "config/kernels.xml"
		kcfg = REXML::Document.new(File.new(kconfig))
		kcfg.elements.each("kernels/kernel") { |k|
			klong = k.elements["long"].text
			kname = k.attributes["short"]
			system("mkdir -p -m 0755 " + builddir + "/stage03/squash/m" + kname )
			system("mkdir -p -m 0755 " + builddir + "/stage03/squash/lib/modules/" + klong )
			system("rsync -aP " + builddir + "/stage01/chroot/lib/modules/" + klong + "/ " +  builddir + "/stage03/squash/m" + kname + "/" )
			system(mksquashfs + " " + builddir + "/stage03/squash/m" + kname + " " + builddir + "/stage03/squash/m" + kname + ".sqs -noappend" )
		}
		# FIXME! FIXME! FIXME!
		system("mv " + builddir + "/stage03/squash/usr/bin " + builddir + "/stage03/squash/usrbin")
		system("mv " + builddir + "/stage03/squash/lib/firmware " + builddir + "/stage03/squash/")
		system("mkdir " + builddir + "/stage03/squash/lib/firmware" )
		system("mkdir -m 0755 " + builddir + "/stage03/squash/usr/bin")
		## if system("test -d " + builddir + "/stage03/squash/opt/kaspersky")
		##	system("mv " + builddir + "/stage03/squash/opt/kaspersky " + builddir + "/stage03/squash/optkaspersky")
		##	system("mkdir -m 0755 " + builddir + "/stage03/squash/opt/kaspersky")
		## end
		squashdirs.each { |d|
			if system("test -d " + builddir + "/stage03/squash/" + d)
				system(mksquashfs + " " + builddir + "/stage03/squash/" + d + " " + builddir + "/stage03/squash/" + d + ".sqs -noappend" ) 
			end
		}
		squashdirs.each { |d|
			system("rm -rf " + builddir + "/stage03/squash/" + d ) 
		}
	end
	
	def ThirdStage.sync_overlay(builddir, overlaydir)
		system("rsync -avHP '" + overlaydir + "/' " + builddir  + "/stage03/initramfs/")
	end
	
	def ThirdStage.write_branding(builddir, branding, brandfile, build_timestamp)
		root = branding.root
		# Write branding variables
		root.elements.each("strings") { |str|
			strlang = str.attributes["lang"]
			# system("mkdir " + builddir + "/stage03/initramfs/etc/lesslinux/branding")
			langvars = File.new(builddir + "/stage03/initramfs/etc/lesslinux/branding/branding." + strlang + ".sh", "w")
			str.elements.each("brandstr") { |brandstr|
				langvars.write(brandstr.attributes["id"] + "=\"" +  brandstr.text.strip + "\"\n")
			}
			langvars.write("brandshort=\"" + root.elements["brandshort"].text.strip + "\"\n")
			langvars.close
			system("chmod 0755 " + builddir + "/stage03/initramfs/etc/lesslinux/branding/branding." + strlang + ".sh")
		}
		# Write filelist to softlink
		filevars = File.new(builddir + "/stage03/initramfs/etc/lesslinux/branding/files.sh", "w")
		filelist = File.new(builddir + "/stage03/initramfs/etc/lesslinux/branding/filelist.txt", "w")
		root.elements.each("files") { |fsec|
			fsec.elements.each("file") { |f|
				filevars.write(f.attributes["id"] + "=\"" +  f.text.strip + "\"\n")
				filelist.write(f.text.strip + "\n")
			}
		}
		filevars.close
		system("chmod 0755 " + builddir + "/stage03/initramfs/etc/lesslinux/branding/files.sh", "w")
		filelist.close
		# copy plain XML file
		system("cp '" +  brandfile + "' " + builddir + "/stage03/initramfs/etc/lesslinux/branding/branding.xml")
		# Write updatekey
		updatekey = File.new(builddir + "/stage03/initramfs/etc/lesslinux/updater/updatekey.asc", "w")
		updatekey.write(root.elements["updater/key"].cdatas[0])
		updatekey.close
		# Write baseurl
		baseurl = File.new(builddir + "/stage03/initramfs/etc/lesslinux/updater/baseurl.txt", "w")
		baseurl.write(root.elements["updater/baseurl"].text)
		baseurl.close
		# Write version info
		version = File.new(builddir + "/stage03/initramfs/etc/lesslinux/updater/version.txt", "w")
		version.write(root.elements["updater/buildidentifier"].text + build_timestamp + "\n")
		version.close
		# Write ISO UUID
		isouuid = File.new(builddir + "/stage03/initramfs/etc/lesslinux/updater/isouuid.txt", "w")
		isouuid.write("#{build_timestamp[0..3]}-#{build_timestamp[4..5]}-#{build_timestamp[6..7]}-#{build_timestamp[9..10]}-#{build_timestamp[11..12]}-#{build_timestamp[13..14]}-00")
		isouuid.close
		# Write git commit ID
		gitcommit = ` git log | head -n1 `.strip.split[1] 
		commitid = File.new(builddir + "/stage03/initramfs/etc/lesslinux/updater/version.git", "w")
		commitid.write(gitcommit)
		commitid.close
		# system("cp -v " + builddir + "/stage03/initramfs/etc/lesslinux/updater/version.txt " + builddir + "/stage03/cdmaster/lesslinux/version.txt")
		# Write command:
		lnum = 0
		scol = 0
		IO.popen("ps wax") { |l|
			while l.gets    
				if lnum < 1 
					scol = $_.index("COMMAND")
				elsif scol > 0
					pid = $_.strip.split[0].to_i
					if pid == $$
						buildcli = File.new(builddir + "/stage03/initramfs/etc/lesslinux/updater/command.sh", "w")
						buildcli.write($_[27..-2])
						buildcli.close
					end                                             
				end
				lnum += 1 
			end
		}
	end
	
	def ThirdStage.full_install(builddir)
		initramfsdirs = ["etc", "static",  "var" ]
		ignoredirs = [ "boot",  "dev", "home", "llbuild", "media", "mnt", "proc", "root", "sys", "tmp", "tools" ]
		squashdirs = [ "bin",  "lib",  "opt", "sbin",  "srv", "usr" ]
		initramfsdirs.each { |d| 
			system("tar -C " + builddir + "/stage01/chroot -cf - " + d + " | tar -C " + builddir + "/stage03/initramfs -xvf - ")
		}
		squashdirs.each { |d| 
			system("tar -C " + builddir + "/stage01/chroot -cf - " + d + " | tar -C " + builddir + "/stage03/squash -xvf - ")
		}
		system("rm -rf " + builddir + "/stage03/squash/lib/modules" )
		system("mkdir " + builddir + "/stage03/squash/lib/modules" )
	end
	
	def ThirdStage.read_skiplist(filename)
		return Array.new if filename.nil?
		return Array.new unless File.exist?(filename)
		skipfiles = Array.new
		skipdirs = Array.new
		File.open(filename).each { |line|
			unless line.strip.length < 1 || line.strip =~ /^\#/
				if line.strip =~ /\/$/ 
					skipdirs.push(line.strip)
				else
					skipfiles.push(line.strip) 
				end
			end
		}
		return skipfiles, skipdirs
	end
	
end
