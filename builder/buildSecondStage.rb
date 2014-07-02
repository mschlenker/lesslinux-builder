

class SecondStage < AnyStage
	
	def SecondStage.mount(builddir, srcdir)
		system("mount -o bind /tmp " + builddir + "/stage01/chroot/tmp")
		system("mount -o bind /dev " + builddir + "/stage01/chroot/dev")
		system("mount -o bind " + builddir + "/stage02/build " + builddir + "/stage01/chroot/llbuild/build")
		system("mount -o bind " + srcdir + " " + builddir + "/stage01/chroot/llbuild/src")
		system("mount -vt devpts devpts " + builddir + "/stage01/chroot/dev/pts")
		system("mount -vt tmpfs shm     " + builddir + "/stage01/chroot/dev/shm")
		system("mount -vt tmpfs tmpfs   " + builddir + "/stage01/chroot/root")
		system("mount -vt tmpfs tmpfs   " + builddir + "/stage01/chroot/tmp")
		system("mount -vt proc proc     " + builddir + "/stage01/chroot/proc")
		system("mount -vt sysfs sysfs   " + builddir + "/stage01/chroot/sys")
	end
	
	def SecondStage.umount(builddir)
		system("umount " + builddir + "/stage01/chroot/sys")
		system("umount " + builddir + "/stage01/chroot/proc")
		system("umount " + builddir + "/stage01/chroot/tmp")
		system("umount " + builddir + "/stage01/chroot/root")
		system("umount " + builddir + "/stage01/chroot/dev/shm")
		system("umount " + builddir + "/stage01/chroot/dev/pts")
		system("umount " + builddir + "/stage01/chroot/llbuild/src")
		system("umount " + builddir + "/stage01/chroot/llbuild/build")
		system("umount " + builddir + "/stage01/chroot/dev")
		system("umount " + builddir + "/stage01/chroot/tmp")
	end
	
	def read_known
		pfile = nil
		searchdir = "./"
		unless @nonfree.nil?
			searchdir = "#{@nonfree}/" 
		end
		if File.exists?(searchdir + "scripts/pkg_content/" + @pkg_name + "-" + @pkg_version + ".xml" )
			if @unstable == true && File.exists?(searchdir + "scripts/pkg_content.unstable/" + @pkg_name + "-" + @pkg_version + ".xml" )
				pfile = REXML::Document.new(File.new(searchdir + "scripts/pkg_content.unstable/" + @pkg_name + "-" + @pkg_version + ".xml", "r"))
			else
				pfile = REXML::Document.new(File.new(searchdir + "scripts/pkg_content/" + @pkg_name + "-" + @pkg_version + ".xml", "r"))
			end
		elsif File.exists?("scripts/pkg_content/" + @pkg_name + "-" + @pkg_version + ".xml" )
			if @unstable == true && File.exists?("scripts/pkg_content.unstable/" + @pkg_name + "-" + @pkg_version + ".xml" )
				pfile = REXML::Document.new(File.new("scripts/pkg_content.unstable/" + @pkg_name + "-" + @pkg_version + ".xml", "r"))
			else
				pfile = REXML::Document.new(File.new("scripts/pkg_content/" + @pkg_name + "-" + @pkg_version + ".xml", "r"))
			end
		else
			puts sprintf("%015.4f", Time.now.to_f) + " build  > No cached file output for " + @pkg_name + " " + @pkg_version + " (no pkg_content file found)"
			$stdout.flush
			return true
		end
		fct = 0
		act = 0
		pfile.elements.each("pkgdesc/subpackage") { |p|
			p.elements.each("file") { |f|
				act += 1
				unless f.attributes["fileout"].nil?
					# puts f.attributes["path"] + " - " + f.attributes["fileout"]
					# begin
						# db.execute( "select * from table where a = ? and b = ?", "hello", "world" )
						# CREATE TABLE knownfiles (id INTEGER PRIMARY KEY ASC, pkg_name VARCHAR(80), pkg_version VARCHAR(40), fname TEXT, fileout TEXT);
						@sqlite.execute("INSERT INTO knownfiles (pkg_name, pkg_version, fname, fileout) VALUES ( ?, ?, ?, ? )", 
							SQLite3::Database.quote(@pkg_name), 
							SQLite3::Database.quote(@pkg_version), 
							SQLite3::Database.quote(f.attributes["path"]), 
							SQLite3::Database.quote(f.attributes["fileout"]) )
						fct += 1
					#rescue
					#end
				end
			}
		}
		if fct < 1
			puts sprintf("%015.4f", Time.now.to_f) + " build  > No cached file output for " + @pkg_name + " " + @pkg_version
			$stdout.flush
		end
		pfile = nil
	end
	
	def build(log, trace)
		if File.exists?(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/build.success") 
			### puts "-> previous build of " + @pkg_name + " successful"
			puts sprintf("%015.4f", Time.now.to_f) + " build  > Previous build of " + @pkg_name + " " + @pkg_version + " successful"
			$stdout.flush
		else
			start_time = Time.new.to_i
			@pkg_time = start_time
			puts sprintf("%015.4f", Time.now.to_f) + " build  > Start building " + @pkg_name + " " + @pkg_version
			$stdout.flush
			# puts "-> building " + @pkg_name + " " + @pkg_version 
			### Dir.chdir(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version)
			# Mount functions
			mscript = File.open(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/mount.sh", 'w')
			mscript.write("for i in /dev /tmp\ndo\nmount -o bind ${i} ${CHROOTDIR}${i}\ndone\n")
			mscript.write("mount -o bind " + @builddir + "/stage02/build ${CHROOTDIR}/llbuild/build\n")
			mscript.write("mount -o bind " + @srcdir + " ${CHROOTDIR}/llbuild/src\n")
			mscript.write("mount -vt devpts devpts ${CHROOTDIR}/dev/pts\n")
			mscript.write("mount -vt tmpfs shm ${CHROOTDIR}/dev/shm\n")
			mscript.write("mount -vt tmpfs tmpfs ${CHROOTDIR}/root\n")
			mscript.write("mount -vt tmpfs tmpfs ${CHROOTDIR}/tmp\n")
			mscript.write("mount -vt proc proc ${CHROOTDIR}/proc\n")
			mscript.write("mount -vt sysfs sysfs ${CHROOTDIR}/sys\n")
			mscript.close
			# Umount functions
			uscript = File.open(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/umount.sh", 'w')
			uscript.write("for i in /dev/pts /dev/shm /dev /proc /tmp /llbuild/src /llbuild/build /sys /root \ndo\numount ${CHROOTDIR}${i}\ndone\n\n")
			uscript.write("for i in /dev/pts /dev/shm /dev /proc /tmp /llbuild/src /llbuild/build /sys /root \ndo\n")
			uscript.write("if mountpoint ${CHROOTDIR}${i}\n then \n")
			uscript.write(" \n sleep 10 \n umount ${CHROOTDIR}${i} \n fi \n");
			uscript.write("if mountpoint ${CHROOTDIR}${i}\n then \n")
			uscript.write(" \n echo \"${CHROOTDIR}${i} still mounted, please unmount and press enter\" \n read z \n fi \n");
			uscript.write("done\n");
			uscript.write("if mountpoint ${CHROOTDIR}/llbuild/build \n then \n")
			uscript.write(" \n echo \"${CHROOTDIR}/llbuild/build still mounted, please unmount and press enter\" \n read z \n fi \n");
			uscript.write("if mountpoint ${CHROOTDIR}/llbuild/src \n then \n")
			uscript.write(" \n echo \"${CHROOTDIR}/llbuild/src still mounted, please unmount and press enter\" \n read z \n fi \n");
			uscript.close
			# Script to enter chroot and trigger the buildscript
			bscript = File.open(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/chroot_and_build.sh", 'w')
			bscript.write("#!/bin/bash\n")
			bscript.write("cd " + @builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "\n")
			bscript.write("CHROOTDIR='" + @builddir + "/stage01/chroot'; export CHROOTDIR\n")
			bscript.write("if [ -x ${CHROOTDIR}/usr/bin/strace ] ; then STRACE=/usr/bin/strace ; else STRACE=/tools/bin/strace ; fi ; \n")
			bscript.write("### . ./mount.sh > /dev/null 2>&1 \n")
			bscript.write("if [ -f ${CHROOTDIR}/usr/bin/env ] && [ -f ${CHROOTDIR}/bin/bash ] ; then\n")
			# FIXME: Do the strace just when necessary!
			if (trace == true || @depends_on.nil?) 
				bscript.write('chroot ${CHROOTDIR} /usr/bin/env -i HOME=/root TERM="$TERM" PS1=\'\u:\w\$ \'' + 
					' PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin ' + 
					' ${STRACE} -f -e trace=file,process -o /llbuild/build/' + @pkg_name +  "-" + @pkg_version + '.strace.build.log ' +
					' /bin/bash +h /llbuild/build/' + @pkg_name +  "-" + @pkg_version + "/build_in_chroot.sh\n")
				bscript.write("else\n")
				bscript.write('chroot ${CHROOTDIR} /tools/bin/env -i HOME=/root TERM="$TERM" PS1=\'\u:\w\$ \'' + 
					' PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin ' + 
					' ${STRACE} -f -e trace=file,process -o /llbuild/build/' + @pkg_name +  "-" + @pkg_version + '.strace.build.log ' +
					' /tools/bin/bash +h /llbuild/build/' + @pkg_name +  "-" + @pkg_version + "/build_in_chroot.sh\n")
			else
				bscript.write('chroot ${CHROOTDIR} /usr/bin/env -i HOME=/root TERM="$TERM" PS1=\'\u:\w\$ \'' + 
					' PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin ' + 
					' /bin/bash +h /llbuild/build/' + @pkg_name +  "-" + @pkg_version + "/build_in_chroot.sh\n")
				bscript.write("else\n")
				bscript.write('chroot ${CHROOTDIR} /tools/bin/env -i HOME=/root TERM="$TERM" PS1=\'\u:\w\$ \'' + 
					' PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin ' + 
					' /tools/bin/bash +h /llbuild/build/' + @pkg_name +  "-" + @pkg_version + "/build_in_chroot.sh\n")
			end
			bscript.write("fi\n")
			bscript.write("### . ./umount.sh > /dev/null 2>&1 \n")
			bscript.close
			File.chmod(0755, @builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/chroot_and_build.sh")
			# Write the buildscript to be triggered
			tscript = File.open(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/build_in_chroot.sh", 'w')
			tscript.write("#!/bin/bash\n")
			tscript.write("cd /llbuild/build/" + @pkg_name + "-" + @pkg_version + "\n\n")
			tscript.write(". ./common_vars\n")
			tscript.write("DISTCC_POTENTIAL_HOSTS='" + @distcchosts.join(" ") + "'; export DISTCC_POTENTIAL_HOSTS\n")
			tscript.write("DISTCC_HOSTCOUNT=" + @distcchosts.size.to_s + "; export DISTCC_HOSTCOUNT\n")
			tscript.write("SRCDIR=/llbuild/src; export SRCDIR\n")
			tscript.write("TGTDIR=/llbuild/build/${PKGNAME}-${PKGVERSION}.destdir ; export TGTDIR\n")
			tscript.write("LC_ALL=POSIX; export LC_ALL\n\n")                         
			tscript.write(@xfile.elements["llpackages/package/build"].cdatas[0])
			tscript.write("\n\n")
			tscript.close
			File.chmod(0755, @builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/build_in_chroot.sh")
			sleep 0.5
			if log == true
				puts sprintf("%015.4f", Time.now.to_f) + " build  > be patient... logging in progress"
				retval = system(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/chroot_and_build.sh > " + @builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + ".build.log 2>&1" )
			else
				retval = system(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/chroot_and_build.sh")
			end
			end_time = Time.new.to_i
			### if (retval == true)
			File.open(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/build.success", "w") { |f| f.write(end_time.to_s + "\n") }
			### end
			unless (retval == true)
				File.open(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/build.failed", "w") { |f| f.write(end_time.to_s + "\n") }
			end
			File.open(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/build.stats", "w") { |f| 
				f.write("start " + start_time.to_s + "\n")
				f.write("end   " + end_time.to_s + "\n")
			}
			puts sprintf("%015.4f", Time.now.to_f) + " build  > Finished building " + @pkg_name + " " + @pkg_version
			$stdout.flush
		end
	end

	def uninstall
		# uninstall all currently installed versions of this package
		files = Array.new
		dirs = Array.new
		fileset = @sqlite.query( "SELECT distinct fname FROM llfiles WHERE stage='stage02' " + 
			" AND pkg_name=? AND (ftype='f' OR ftype='l') ", [ SQLite3::Database.quote(@pkg_name) ] )
		fileset.each { |i| 
			checkset = @sqlite.query( "SELECT distinct pkg_name, pkg_version FROM llfiles WHERE stage='stage02' " + 
			" AND fname=? AND pkg_name!=? AND (ftype='f' OR ftype='l') ", [ SQLite3::Database.quote(i[0].strip), SQLite3::Database.quote(@pkg_name) ] )
			# sqlite_libset.push(i[0].strip)
			interfers = 0
			checkset.each { |j|
				interfers += 1
				puts "*> unable to remove " + i[0].strip + " collides with package " + j[0] + " " + j[1]
			}
			files.push(i[0]) if interfers < 1
		}
		dirset = @sqlite.query( "SELECT distinct fname FROM llfiles WHERE stage='stage02' " + 
			" AND pkg_name=? AND ftype='d' ", [ SQLite3::Database.quote(@pkg_name) ] )
		dirset.each { |i| dirs.push(i[0]) }
		dirs.sort!
		# Now delete softlinks and files first
		files.each { |i|
			if File.exist?(@builddir + "/stage01/chroot" + i)
				puts " > deleting " + i
				File.unlink(@builddir + "/stage01/chroot" + i)
			end
		}
		dirs.each { |i|
			if File.exist?(@builddir + "/stage01/chroot" + i)
				begin 
					puts " > deleting " + i
					Dir.rmdir(@builddir + "/stage01/chroot" + i)
				rescue Errno::ENOTEMPTY
					puts "*> Ooops " + i + " not empty "
				end
			end
		}
		
	end

	def install(log, trace)
		if File.exists?(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/install.success") 
			puts sprintf("%015.4f", Time.now.to_f) + " build  > Previous install of " + @pkg_name + " " + @pkg_version + " successful"
			$stdout.flush
		else
			start_time = Time.now.to_i
			# puts sprintf("%015.4f", Time.now.to_f) + " debug  > Read known pkg_content for " + @pkg_name + " " + @pkg_version
			# read_known
			# puts sprintf("%015.4f", Time.now.to_f) + " debug  > Done"
			### uninstall unless @pkg_name == "coreutils"
			puts sprintf("%015.4f", Time.now.to_f) + " build  > Start installing " + @pkg_name + " " + @pkg_version
			$stdout.flush
			### Dir.chdir(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version)
			# Script to enter chroot and trigger the installscript
			bscript = File.open(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/chroot_and_install.sh", 'w')
			system("mkdir -p \"" +  @builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + ".destdir\"")
			bscript.write("#!/bin/bash\n")
			bscript.write("cd " + @builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "\n") 
			bscript.write("CHROOTDIR='" + @builddir + "/stage01/chroot'; export CHROOTDIR\n")
			bscript.write("if [ -x ${CHROOTDIR}/usr/bin/strace ] ; then STRACE=/usr/bin/strace ; else STRACE=/tools/bin/strace ; fi ; \n ")
			bscript.write("### . ./mount.sh > /dev/null 2>&1 \n")
			if (trace == true || @depends_on.nil?) 
				bscript.write('chroot ${CHROOTDIR} /tools/bin/env -i HOME=/root TERM="$TERM" PS1=\'\u:\w\$ \'' + 
					' PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin ' + 
					' ${STRACE} -f -e trace=file,process -o /llbuild/build/' + @pkg_name +  "-" + @pkg_version + '.strace.install.log ' +
					' /tools/bin/bash /llbuild/build/' + @pkg_name + "-" + @pkg_version + "/install_in_chroot.sh\n")
			else
				bscript.write('chroot ${CHROOTDIR} /tools/bin/env -i HOME=/root TERM="$TERM" PS1=\'\u:\w\$ \'' + 
					' PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin ' + 
					' /tools/bin/bash /llbuild/build/' + @pkg_name + "-" + @pkg_version + "/install_in_chroot.sh\n")
			end
			bscript.write("### . umount.sh > /dev/null 2>&1 \n")
			bscript.close
			File.chmod(0755, @builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/chroot_and_install.sh")
			# Write the installscript to be triggered
			tscript = File.open(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/install_in_chroot.sh", 'w')
			tscript.write("#!/bin/bash\n")
			tscript.write("cd /llbuild/build/" + @pkg_name + "-" + @pkg_version + "\n\n")
			tscript.write(". common_vars\n")
			tscript.write("SRCDIR=/llbuild/src; export SRCDIR\n")
			tscript.write("TGTDIR=/llbuild/build/${PKGNAME}-${PKGVERSION}.destdir ; export TGTDIR\n")
			tscript.write("LC_ALL=POSIX; export LC_ALL\n\n")
			tscript.write(@xfile.elements["llpackages/package/install"].cdatas[0])
			tscript.write("\n\n")
			tscript.close
			File.chmod(0755, @builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/install_in_chroot.sh")
			sleep 0.5
			if log == true
				puts sprintf("%015.4f", Time.now.to_f) + " build  > be patient... logging in progress"
				retval = system(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/chroot_and_install.sh > " + @builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + ".install.log 2>&1" )
			else
				retval = system(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/chroot_and_install.sh")
			end
			try_again_count = 0
			while log == true && try_again_count < 100 && system("tail -n 2 " + @builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + ".install.log | grep -qi ' Text file busy' ")
				puts sprintf("%015.4f", Time.now.to_f) + " build  > Install Error Text file busy " + @pkg_name + " " + @pkg_version
				$stdout.flush
				sleep 5.0
				retval = system(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/chroot_and_install.sh > " + @builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + ".install.log 2>&1" )
				try_again_count += 1 
			end
			end_time = Time.now.to_i
			#### if (retval == true)
			File.open(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/install.success", "w") { |f| 
				f.write(Time.now.to_i.to_s + "\n")
			}
			### end
			unless (retval == true)
				File.open(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/install.failed", "w") { |f| 
					f.write(Time.now.to_i.to_s + "\n")
				}
			end
			File.open(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/install.stats", "w") { |f| 
				f.write("start " + start_time.to_s + "\n")
				f.write("end   " + end_time.to_s + "\n")
			}
			if @target_type == "destdir"
				system("tar -C " + @builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + ".destdir -cf - . | tar -C " +  @builddir + "/stage01/chroot/ -xf - ")
				system("chroot " +  @builddir + "/stage01/chroot/ ldconfig ")
			end
			puts sprintf("%015.4f", Time.now.to_f) + " build  > Finished installing " + @pkg_name + " " + @pkg_version
			$stdout.flush
		end
	end
	
	# test functionality
	def test_func
		if @xfile.elements["llpackages/package/test"].cdatas.size < 1 || File.exists?(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/test.success") 
			puts '-> skipping tests'
		else
			puts "-> testing " + @pkg_name + " " + @pkg_version 
			### Dir.chdir(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version )
			# Script to enter chroot and trigger the testscript
			bscript = File.open(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/chroot_and_test.sh", 'w')
			bscript.write("#!/bin/bash\n")
			bscript.write("cd " + @builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "\n")
			bscript.write("CHROOTDIR='" + @builddir + "/stage01/chroot'; export CHROOTDIR\n")
			bscript.write(". mount.sh\n")
			bscript.write('chroot ${CHROOTDIR} /tools/bin/env -i HOME=/root TERM="$TERM" PS1=\'\u:\w\$ \'' + 
				' PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin ' + 
				' /tools/bin/bash /llbuild/build/' + @pkg_name + "-" + @pkg_version + "/test_in_chroot.sh\n")
			bscript.write(". umount.sh\n")
			bscript.close
			File.chmod(0755, @builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/chroot_and_test.sh")
			# Write the testscript to be triggered
			tscript = File.open(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/test_in_chroot.sh", 'w')
			tscript.write("#!/bin/bash\n")
			tscript.write("cd /llbuild/build/" + @pkg_name +  "-" + @pkg_version + "\n\n")
			tscript.write(". common_vars\n")
			tscript.write("SRCDIR=/llbuild/src; export SRCDIR\n")
			tscript.write("LC_ALL=POSIX; export LC_ALL\n\n")
			tscript.write(@xfile.elements["llpackages/package/test"].cdatas[0])
			tscript.write("\n\n")
			tscript.close
			File.chmod(0755, @builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/test_in_chroot.sh")
			retval = system(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/chroot_and_test.sh")
			puts '=> type "Yes" if the result of the test of ' + @pkg_name + " " + @pkg_version + " looks reasonable "
			rstring = $stdin.read
			if (rstring.strip == "Yes" )
				File.open("test.success", "w") { |f| f.write(Time.now.to_i.to_s + "\n") }
			else 
				raise "TestFailed"
			end
		end
	end
	
	def filecheck(queue_name=nil)
		# Read all files
		ignore_dirs = [ "/dev", "/tools", "/proc", "/tmp" ]
		check_dirs = [ "bin", "boot", "etc", "lib", "opt", "sbin", "share", "tools", "usr", "var", "static" ] 
		check_exps = check_dirs.collect { |x|
			if (@target_type == "chroot" && File.exist?(@builddir + "/stage01/chroot/" + x))
				File.expand_path(@builddir + "/stage01/chroot/" + x)
			elsif (@target_type == "destdir"&& File.exist?(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + ".destdir/" + x)) 
				File.expand_path(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + ".destdir/" + x)
			else
				""
			end
		} 
		if File.exists?(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/check.success") 
			puts sprintf("%015.4f", Time.now.to_f) + " check  > Previous check of " + @pkg_name + " " + @pkg_version + " successful"
			$stdout.flush
		else
			maho = Mahoro.new(Mahoro::NONE)
			modified_files = 0
			### files_abs_path, files_rel_path = extract_strace
			expdir = File.expand_path(@builddir + "/stage01/chroot")
			expdir = File.expand_path(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + ".destdir") if  @target_type == "destdir"
			reprexp = Regexp.new('^' + expdir)
			f_tuples = Hash.new
			d_tuples = Hash.new
			l_tuples = Hash.new
			# Query all files from database
			qstring = "SELECT fname, fsize, modtime, ftype FROM llfiles WHERE ftype='f' ORDER BY fname ASC, modtime ASC "
			# puts qstring
			# resset = @dbh.query(qstring)
			resset = @sqlite.query(qstring)
			resset.each { |r|
				fpath = r[0].sub(reprexp, '').strip
				f_tuples[fpath] = [ r[1].to_i , r[2].to_i ]
			}
			qstring = "SELECT fname, modtime, ftype FROM llfiles WHERE ftype='d' ORDER BY fname ASC, modtime ASC "
			# resset = @dbh.query(qstring)
			resset = @sqlite.query(qstring)
			resset.each { |r|
				fpath = r[0].sub(reprexp, '').strip
			 	d_tuples[fpath] = r[1].to_i 
			}
			qstring = "SELECT fname, modtime, ftype FROM llfiles WHERE ftype='l' ORDER BY fname ASC, modtime ASC "
			# resset = @dbh.query(qstring)
			resset = @sqlite.query(qstring)
			resset.each { |r|
				fpath = r[0].sub(reprexp, '').strip
				l_tuples[fpath] = r[1].to_i 
			}
			# puts("find " + expdir + " -xdev -type f -printf '%T@ %s %h/%f\\n'")
			# raise "DebugBreakpoint"
			rawfindouts = Array.new
			IO.popen("find " + check_exps.join(" ") + " -xdev -type f -printf '%T@-+-%s-+-%h/%f\\n'") { |f|
				while f.gets
					rawfindouts.push($_)
				end
			}
			rawfindouts.each { |fo|
				#begin
					### puts "Checking " + $_.strip
					triple = fo.strip.split('-+-')
					fpath = triple[2].sub(reprexp, '').strip
					fsize = triple[1].to_i
					modtime = triple[0].to_i
					forbidden = nil
					ignore_dirs.each { |d|
						if fpath.index(d) == 0
							forbidden = true
						end
					}
					if forbidden.nil?
						if @target_type == "destdir" || f_tuples[fpath].nil?
							# puts ' => checking ' + fpath + ' ' + modtime.to_s + ' nil ' + fsize.to_s + ' nil'
							x = FileChecker.new(fpath, modtime, nil, fsize, nil, 
								expdir, @pkg_name, @pkg_time, @pkg_version, "f", "stage02", @dbh, @sqlite, maho)
							modified_files += x.save
						else
							if f_tuples[fpath][1].to_i != modtime || f_tuples[fpath][0].to_i != fsize
								x = FileChecker.new(fpath, modtime, f_tuples[fpath][1].to_i, fsize, f_tuples[fpath][0].to_i, 
								expdir, @pkg_name, @pkg_time, @pkg_version, "f", "stage02", @dbh, @sqlite, maho)
								modified_files += x.save
							end
						end
					end
				#rescue
					# puts "*> failed checking line " + fo.strip 
				#end
			}
			
			# raise "DebugBreakpoint"
			# Query all dirs from database
			# Read all dirs
			IO.popen("find " + check_exps.join(" ") + " -xdev -type d -printf '%T@-+-%s-+-%h/%f\\n'") { |f|
				while f.gets
					### puts "Checking " + $_.strip
					triple = $_.strip.split('-+-')
					fpath = triple[2].sub(reprexp, '').strip
					modtime = triple[0].to_i
					# if d_tuples[fpath].to_i != modtime
					# just check for dirs that did not exist before
					if @target_type == "destdir" || d_tuples[fpath].nil?
						x = FileChecker.new(fpath, modtime, d_tuples[fpath].to_i, 0, 0, 
							expdir, @pkg_name, @pkg_time, @pkg_version, "d", "stage02", @dbh, @sqlite, maho)
						# modified_files += x.save
						x.save
					end
				end
			}
			# Read all Softlinks
			# Query all softlinks from database
			IO.popen("find " + check_exps.join(" ") + " -xdev -type l -printf '%T@-+-%s-+-%h/%f\\n'") { |f|
				while f.gets
					### puts "Checking " + $_.strip
					triple = $_.strip.split('-+-')
					fpath = triple[2].sub(reprexp, '').strip
					modtime = triple[0].to_i
					# if l_tuples[fpath].to_i != modtime
					# just check for softlinks that did not exist before
					# FIXME: also check for changed softlinks!
					if @target_type == "destdir" || l_tuples[fpath].nil?
						x = FileChecker.new(fpath, modtime, l_tuples[fpath].to_i, 0, 0, 
							expdir, @pkg_name, @pkg_time, @pkg_version, "l", "stage02", @dbh, @sqlite, maho)
						x.save
						# modified_files += x.save
					end
				end
			}
			if modified_files > 0
				File.open(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + "/check.success", "w") { |f| 
					f.write(Time.now.to_i.to_s + "\n")
				}
				system("mkdir -p " + @builddir + "/stage01/chroot/etc/lesslinux/pkglist.d") unless File.exist?(@builddir + "/stage01/chroot/etc/lesslinux/pkglist.d")
				File.open(@builddir + "/stage01/chroot/etc/lesslinux/pkglist.d/" +  @pkg_name + ".ver", "w") { |f|
					f.write(@pkg_version.to_s) 
				}
			else
				puts '==> ERROR: No modified files found! Please check the build descriptions!'
				puts '  > Error occured when installing ' + @pkg_name + "-" + @pkg_version
				if (queue_name.to_s == "top")
					puts '  > Failed package is from top queue, so I am continuing!'
				elsif @failpackages.include?(@pkg_name)
					puts '  > Package was explicitely allowed to fail by CLI switch!'
				else
					puts '  > Remove the file ' + @builddir + '/tmp/LessLinux_Emergency_Exit afterwards!'
					system("touch " + @builddir +  "/tmp/LessLinux_Emergency_Exit")
				end
				# raise "NoModifiedFilesFound"
			end
			return modified_files 
		end
	end
	
	def dump_stage03_script
		# dumpfile = REXML::Document.new(File.new("scripts/stage03/added-dependency-" + @pkg_name + ".xml"))
		doc = REXML::Document.new
		doc.add_element("llpackages")
		skel = doc.root.add_element("package")
		skel.add_attribute("name", @pkg_name)
		skel.add_attribute("version", @pkg_version)
		skel.add_attribute("class", "autodep")
		outfile = File.open("scripts/stage03/added-dependency-" + @pkg_name + ".xml", "w")
		doc.write( outfile, 4)
		outfile.close
	end
end
