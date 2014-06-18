
class InitramfsAssembly
	
	def initialize (srcdir, builddir, dbh, cfgfile)
		@srcdir =srcdir
		@builddir = builddir
		@dbh = dbh
		@cfgfile = cfgfile
		# @xfile = REXML::Document.new(File.new(cfgfile))
		@tstamp = Time.new.to_i
	end

	def build
		puts "=> building initramfs"
		ignoredirs = Array.new
		[ "root", "etc", "var", "lib" ] .each { |d| ignoredirs.push(@builddir + "/stage03/initramfs/" + d) }  
		system("mkdir -p " + @builddir  + "/stage03/initramfs/lesslinux/modules/" )
		system("mkdir -p " + @builddir  + "/stage03/switch" )
		system("ln -s /etc/rc " + @builddir  + "/stage03/switch/linuxrc")
		system("ln -s /etc/rc " + @builddir  + "/stage03/switch/init")
		system("rsync -avP "  + @builddir + "/stage03/squash/firmware.sqs " + @builddir  + "/stage03/initramfs/lesslinux/modules/" )
		create_sha1list(@builddir + "/stage03/initramfs", @builddir + "/stage03/initramfs/initramfs.sha", ignoredirs ) 
		# puts "-> creating list of files"
		# system("bash ./bin/scripts/gen_initramfs_list.sh " + @builddir + "/stage03/initramfs > " + @builddir + "/tmp/initramfs.list." + @tstamp.to_s )
		# system("bash ./bin/scripts/gen_initramfs_list.sh " + @builddir + "/stage03/switch > " + @builddir + "/tmp/switch.list." + @tstamp.to_s )
		puts "-> packing initramfs"
		# system("./bin/i686/gen_init_cpio " + @builddir + "/tmp/initramfs.list." +  @tstamp.to_s + " | gzip -c > " + @builddir + "/stage03/initramfs.gz" )
		# system("./bin/i686/gen_init_cpio " + @builddir + "/tmp/switch.list." +  @tstamp.to_s + " | gzip -c > " + @builddir + "/stage03/switch.gz" )
		system("/bin/bash notes/create_initramfs.sh " + @builddir + "/stage03/initramfs " + @builddir + "/stage03/initramfs.gz")
		system("/bin/bash notes/create_initramfs.sh " + @builddir + "/stage03/switch    " + @builddir + "/stage03/switch.gz")
		return @builddir + "/stage03/initramfs.gz"
	end

	def assemble_modules(cfgfile, modmodel)
		kcfg = REXML::Document.new(File.new(cfgfile))
		rsyncable = ""
		rsyncable = "--rsyncable" if system("gzip --help | grep -q rsyncable")
		kcfg.elements.each("kernels/kernel") { |k|
			klong = k.elements["long"].text
			kname = k.attributes["short"]
			puts "=> adding modules for " + klong
			if modmodel == "new"
				system("mkdir -p " + @builddir + "/stage03/cpio-" + kname + "/lesslinux/modules")
				system("mv " + @builddir + "/stage03/squash/m" + kname + ".sqs " + 
					@builddir + "/stage03/cpio-" + kname + "/lesslinux/modules/" + klong + ".sqs")
			end
			create_sha1list(@builddir + "/stage03/cpio-" + kname, @builddir + "/stage03/cpio-#{kname}/modules.sha", [] )
			# puts '-> creating list of files '
			# system("bash ./bin/scripts/gen_initramfs_list.sh " + @builddir + "/stage03/cpio-" + kname + " > " + @builddir + "/tmp/cpio-" + kname + ".list." + @tstamp.to_s )
			puts '-> packing initramfs for ' +  klong
			# system("./bin/i686/gen_init_cpio " + @builddir + "/tmp/cpio-" + kname + ".list." +  @tstamp.to_s + " | gzip -c " + rsyncable + " > " + @builddir + "/stage03/cpio-" + kname + ".gz" )
			system("/bin/bash notes/create_initramfs.sh " + @builddir + "/stage03/cpio-" + kname + " " + @builddir + "/stage03/cpio-" + kname + ".gz")
		}
	end

	def create_sha1list(dir, txtfile, skipdirs=Array.new)
		filelist = traversedir(dir, skipdirs)
		outfile = File.new(txtfile, "w")
		filelist.each { |f|
			sha = ` sha1sum #{f} `.strip.split
			relpath = f.gsub(dir, '').gsub(/^\//, '')
			outfile.write("#{sha[0]}  #{relpath}\n")
		}	
		outfile.close
	end
	
	def traversedir(dir, skipdirs=Array.new)
		files = Array.new
		Dir.entries(dir).each { |f|
			unless f == "." || f == ".." 
				if File.symlink?(dir + "/" + f)
					# ignoring symlink
				elsif File.directory?(dir + "/" + f)
					skipthis = false
					skipdirs.each { |s|
						skipthis = true if dir + "/" + f =~ Regexp.new("^"   + s + "$") 
					}
					files = files + traversedir(dir + "/" + f) unless skipthis == true 
				elsif File.file?(dir + "/" + f)
					files.push(dir + "/" + f)
				end
			end
		}
		return files
	end

end