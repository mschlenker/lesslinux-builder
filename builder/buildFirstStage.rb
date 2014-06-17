

class FirstStage < AnyStage

	def build(log=false)
		if File.exists?(@builddir + "/stage01/build/" + @pkg_name + "-" + @pkg_version + "/build.success") 
			puts "-> previous build of " + @pkg_name + " successful"
		else
			puts "-> building " + @pkg_name + " " + @pkg_version
			### Dir.chdir(@builddir + "/stage01/build/" + @pkg_name + "-" + @pkg_version)
			bvars = File.open(@builddir + "/stage01/build/" + @pkg_name + "-" + @pkg_version + "/build_vars", 'w')
			# bvars.write("LFS_TGT=$(uname -m)-lfs-linux-gnu; export LFS_TGT\n")
			# FIXME: Do not hardcode target architecture here!
			arch = ` uname -m `
			if arch =~ /armv6l/
				bvars.write("LFS_TGT=armv6l-lfs-linux-gnueabihf; export LFS_TGT\n")
			else
				bvars.write("LFS_TGT=i686-lfs-linux-gnu; export LFS_TGT\n")
			end
			bvars.write("PATH=/tools/bin:/bin:/usr/bin; export PATH\n")
			bvars.write("LC_ALL=POSIX; export LC_ALL\n")
			bvars.write("CHROOTDIR='" + @builddir + "/stage01/chroot'; export CHROOTDIR\n")
			bvars.close
			bscript = File.open(@builddir + "/stage01/build/" + @pkg_name + "-" + @pkg_version + "/build.sh", 'w')
			bscript.write("#!/bin/bash\n")
			bscript.write("cd " + @builddir + "/stage01/build/" + @pkg_name + "-" + @pkg_version + "\n")
			bscript.write(". common_vars\n. build_vars\n")
			bscript.write(@xfile.elements["llpackages/package/build"].cdatas[0])
			bscript.write("\n# END\n")
			bscript.close
			File.chmod(0755, @builddir + "/stage01/build/" + @pkg_name + "-" + @pkg_version + "/build.sh")
			logstr = ""
			if log == true
				logstr =  " > " + @builddir + "/stage01/build/" + @pkg_name + "-" + @pkg_version + ".build.log 2>&1"
			end
			if @xfile.elements["llpackages/package"].attributes["buildas"].to_s == "unpriv"
				cscript = File.open(@builddir + "/stage01/build/" + @pkg_name + "-" + @pkg_version + "/chown.sh", 'w')
				cscript.write("#!/bin/bash\n")
				cscript.write("cd " + @builddir + "/stage01/build/" + @pkg_name + "-" + @pkg_version +   " \n")
				cscript.write(". common_vars\n")
				cscript.write("UNPRIV=" + @unpriv + "\n")
				cscript.write(@xfile.elements["llpackages/package/chown"].cdatas[0])
				cscript.write("\n# END\n")
				cscript.close
				system("bash " + @builddir + "/stage01/build/" + @pkg_name + "-" + @pkg_version + "/chown.sh")
				retval = system("su " + @unpriv + " " + @builddir + "/stage01/build/" + 
					@pkg_name + "-" + @pkg_version + "/build.sh" + logstr)
			else
				retval = system(@builddir + "/stage01/build/" + @pkg_name + "-" + @pkg_version + "/build.sh" + logstr)
			end
			if (retval == true)
				File.open(@builddir + "/stage01/build/" + @pkg_name + "-" + @pkg_version + "/build.success", "w") {  |f|
					f.write(Time.now.to_i.to_s + "\n")
				}
			end
		end
	end

	def install(log=false)
		if File.exists?(@builddir + "/stage01/build/" + @pkg_name + "-" + @pkg_version + "/install.success") 
			puts "-> previous install of " + @pkg_name + " successful"
		else
			puts "-> installing " + @pkg_name + " " + @pkg_version 
			### Dir.chdir(@builddir + "/stage01/build/" + @pkg_name + "-" + @pkg_version)
			iscript = File.open(@builddir + "/stage01/build/" + @pkg_name + "-" + @pkg_version + "/install.sh", 'w')
			iscript.write("#!/bin/bash\n")
			iscript.write("cd " + @builddir + "/stage01/build/" + @pkg_name + "-" + @pkg_version + "\n")
			iscript.write(". common_vars\n. build_vars\n")
			iscript.write(@xfile.elements["llpackages/package/install"].cdatas[0])
			iscript.write("\n# END\n")
			iscript.close
			logstr = ""
			if log == true
				logstr =  " > " + @builddir + "/stage01/build/" + @pkg_name + "-" + @pkg_version + ".install.log 2>&1"
			end
			retval = system("bash " + @builddir + "/stage01/build/" + @pkg_name + "-" + @pkg_version + "/install.sh" + logstr)
			if (retval == true)
				File.open(@builddir + "/stage01/build/" + @pkg_name + "-" + @pkg_version + "/install.success", "w") { |f| f.write(Time.now.to_i.to_s + "\n") }
			else 
				puts '-> install failed, please check ' + @pkg_name +  " " + @pkg_version
				raise "InstallFailed"
			end
		end
	end
	
	def filecheck
		# Read all files
		if File.exists?(@builddir + "/stage01/build/" + @pkg_name + "-" + @pkg_version + "/check.success") 
			puts "-> previous check of " + @pkg_name + " successful"
		else
			maho = Mahoro.new(Mahoro::NONE)
			modified_files = 0
			expdir = File.expand_path(@builddir + "/stage01/chroot")
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
			IO.popen("find " + expdir + " -xdev -type f -printf '%T@ %s %h/%f\\n'") { |f|
				while f.gets
					triple = $_.strip.split(' ')
					fpath = triple[2].sub(reprexp, '').strip
					fsize = triple[1].to_i
					modtime = triple[0].to_i
					if f_tuples[fpath].nil?
						# puts ' => checking ' + fpath + ' ' + modtime.to_s + ' nil ' + fsize.to_s + ' nil'
						x = FileChecker.new(fpath, modtime, nil, fsize, nil, 
							expdir, @pkg_name, @pkg_time, @pkg_version, "f", "stage01", @dbh, @sqlite, maho)
						modified_files += x.save
					else
						if f_tuples[fpath][1].to_i != modtime || f_tuples[fpath][0].to_i != fsize
							x = FileChecker.new(fpath, modtime, f_tuples[fpath][1].to_i, fsize, f_tuples[fpath][0].to_i, 
							expdir, @pkg_name, @pkg_time, @pkg_version, "f", "stage01", @dbh, @sqlite, maho)
							modified_files += x.save
						end
					end
				end
			}
			# raise "DebugBreakpoint"
			# Query all dirs from database
			# Read all dirs
			IO.popen("find " + expdir + " -xdev -type d -printf '%T@ %s %h/%f\n'") { |f|
				while f.gets
					triple = $_.strip.split(' ')
					fpath = triple[2].sub(reprexp, '').strip
					modtime = triple[0].to_i
					if d_tuples[fpath].to_i != modtime
						x = FileChecker.new(fpath, modtime, d_tuples[fpath].to_i, 0, 0, 
							expdir, @pkg_name, @pkg_time, @pkg_version, "d", "stage01", @dbh, @sqlite, maho)
						modified_files += x.save
					end
				end
			}
			# Read all Softlinks
			# Query all softlinks from database
			IO.popen("find " + expdir + " -xdev -type l -printf '%T@ %s %h/%f\n'") { |f|
				while f.gets
					triple = $_.strip.split(' ')
					fpath = triple[2].sub(reprexp, '').strip
					modtime = triple[0].to_i
					if l_tuples[fpath].to_i != modtime
						x = FileChecker.new(fpath, modtime, l_tuples[fpath].to_i, 0, 0, 
							expdir, @pkg_name, @pkg_time, @pkg_version, "l", "stage01", @dbh, @sqlite, maho)
						modified_files += x.save
					end
				end
			}
			if modified_files > 0
				File.open(@builddir + "/stage01/build/" + @pkg_name + "-" + @pkg_version + "/check.success", "w") { |f| f.write(Time.now.to_i.to_s + "\n") }
			else
				puts '==> ERROR: No modified files found! Please check the build descriptions!'
				raise "NoModifiedFilesFound"
			end
		end
	end
	
end