#!/usr/bin/ruby
# encding: utf-8

require "builder/buildAnyStage.rb"
require "builder/buildFirstStage.rb"
require "builder/buildSecondStage.rb"
require "builder/buildThirdStage.rb"
require "builder/fileDownLoader.rb"
require "builder/singleSourceFile.rb"
require "builder/fileChecker.rb"
require "builder/initramfsAssembly.rb"
require "builder/bootdiskAssembly.rb"
require "builder/packageBuilder.rb"
require "builder/packageVersion.rb"
require "rexml/document"
require "digest/sha1"
# require "mysql"
require 'optparse' 
require 'sqlite3'

def stracalyze(ltype)
	process_directory = Hash.new
	files_accessed = Array.new
	stage_one_accessed = Array.new
	files_missing = Array.new
	puts "-> Analyze strace log (" + ltype + ") from " + @pkg_name + "-" + @pkg_version 
	unless File.exists?(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + ".strace." + ltype + ".log.bz2") || 
		File.exists?(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + ".strace." + ltype + ".log")
		puts "*> No trace log found! Unable to calculate deps for: " + @pkg_name + " " + @pkg_version
		exit 1
	end
	if File.exists?(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + ".strace." + ltype + ".log.bz2")
		puts(".> Unpacking log file...")
		system("bunzip2 " + @builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + ".strace." + ltype + ".log.bz2")
	end
	logfile = File.open(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + ".strace." + ltype + ".log")
	lcount = 0
	logfile.each { |line|
		lcount = lcount + 1
		if lcount % 100000 == 0
			print " " + lcount.to_s + " "
			$stdout.flush
			files_missing = files_missing.uniq
			files_accessed = files_accessed.uniq
			stage_one_accessed = stage_one_accessed.uniq
		elsif lcount % 5000 == 0
			print "."
			$stdout.flush
		end
		pid = line.split[0]
		if line =~ /vfork\(/
			# puts pid
			pdir_old = process_directory[pid]
			if pdir_old.nil?
				pdir_old = "/"
				process_directory[pid] = "/"
			end
			process_directory[line.split[3].strip] = pdir_old
		elsif line =~ /vfork resumed/ 
			if line =~ /^(\d*?)\s.*?\s(\d*?)$/
				# puts line
				# puts $1.strip + " ... " + $2.strip
				pdir_old = process_directory[$1.strip]
				if pdir_old.nil?
					pdir_old = "/"
					process_directory[$1.strip] = "/"
				end
				process_directory[$2.strip] = pdir_old
			end
		elsif line =~ /clone\(/ 
			if line =~ /^(\d*?)\s*?clone\(.*?\)\s*?=\s*?(\d*?)$/
				pdir_old = process_directory[$1.strip]
				if pdir_old.nil?
					pdir_old = "/"
					process_directory[$1.strip] = "/"
				end
				process_directory[$2.strip] = pdir_old
			end
		elsif line =~  /clone resumed/
			if line =~ /^(\d*?)\s.*?\s(\d*?)$/
				# puts line
				# puts $1.strip + " ... " + $2.strip
				pdir_old = process_directory[$1.strip]
				if pdir_old.nil?
					pdir_old = "/"
					process_directory[$1.strip] = "/"
				end
				process_directory[$2.strip] = pdir_old
			end
		elsif line =~ /chdir\(/
			if line =~ /^(\d*?)\s*?chdir\(\"(.*?)\"\)/
				# puts $1.strip + " ... " + $2.strip
				pid = $1.strip
				dir = $2.strip
				pdir_old = process_directory[pid]
				if pdir_old.nil?
					pdir_old = "/"
				end
				if $2.strip =~ /^\//
					process_directory[pid] = dir
				else
					# puts pid + " ... " + process_directory[pid] + " ... " + dir
					process_directory[pid] = File.expand_path(pdir_old + "/" + dir) 
				end
			end
		elsif line =~ /^(\d*?)\s*?(access|open|execve|stat64|lstat64)\(\"(.*?)\".*?=\s(\d*?)$/
			pid = $1.strip
			fname = $3.to_s.strip
			retc = $4.to_s.strip
			if fname =~ /^\// 
				files_accessed.push(File.expand_path(fname)) unless 
					fname =~ /^\/llbuild\// || fname =~ /^\/etc\// || 
					fname =~ /^\/var\// || fname =~ /^\/tools\// ||
					fname =~ /^\/root\// || fname =~ /^\/home\// ||
					fname =~ /^\/tmp\//
				stage_one_accessed.push(File.expand_path(fname)) if fname =~ /^\/tools\//
			elsif fname != ""
				# puts line
				pdir = process_directory[pid]
				if pdir.nil?
					pdir = "/"
					puts "FIXME, fork not found for pid " + pid + " in " +@pkg_name + "-" + @pkg_version
					puts line
				end
				full_fname = File.expand_path(pdir + "/" + fname) 
				# puts pid + " ... " + full_fname + " <- " + fname + " ... " + retc
				files_accessed.push(full_fname) unless 
					full_fname =~ /^\/llbuild\// || full_fname =~ /^\/etc\// || 
					full_fname =~ /^\/var\// || full_fname =~ /^\/tools\// ||
					full_fname =~ /^\/root\// || full_fname =~ /^\/home\// ||
					full_fname =~ /^\/tmp\//
				stage_one_accessed.push(fullname) if fname =~ /^\/tools\//
			end
		elsif line =~ /^(\d*?)\s*?(access|open|execve|stat64|lstat64)\(\"(.*?)\".*?=\s(.*?)ENO/
			pid = $1.strip
			fname = $3.strip
			if fname =~ /^\// && !files_missing.include?(File.expand_path(fname))
				files_missing.push(File.expand_path(fname)) unless
					fname =~ /^\/llbuild\// || fname =~ /^\/etc\// || 
					fname =~ /^\/var\// || fname =~ /^\/tools\// ||
					fname =~ /^\/root\// || fname =~ /^\/home\// ||
					fname =~ /^\/tmp\//
			elsif !files_missing.include?(fname)
				pdir = process_directory[pid]
				if pdir.nil?
					pdir = "/"
					puts "FIXME, fork not found for pid " + pid + " in " +@pkg_name + "-" + @pkg_version
					puts line
				end
				full_fname = File.expand_path(pdir + "/" + fname) 
				# puts pid + " ... " + full_fname + " <- " + fname
				files_missing.push(full_fname) unless 
					full_fname =~ /^\/llbuild\// || full_fname =~ /^\/etc\// || 
					full_fname =~ /^\/var\// || full_fname =~ /^\/tools\// ||
					full_fname =~ /^\/root\// || full_fname =~ /^\/home\// ||
					full_fname =~ /^\/tmp\//
			end
		elsif line =~ /^(\d*?)\s*?exit_group\(0\)/
			pid = $1.strip
			process_directory.delete(pid)
		end
		# unless process_directory.has_key?(pid)
		#	# puts pid
		#	process_directory[pid] = "/"
		# end
	}
	logfile.close
	#puts "FOUND ==== "	
	#files_accessed.sort.uniq.each { |f|
	#	puts f
	#}
	#puts "MISSING =====" 
	#files_missing.sort.uniq.each { |f|
	#	puts f
	#}
	print "\n"
	softlines = find_deps_searched(files_missing.uniq)
	hardlines = find_deps_accessed(files_accessed.uniq)
	toollines = find_deps_tools(stage_one_accessed.uniq)
	depfile = File.open(@builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + ".dependencies." + ltype + ".txt", "w")
	hardlines.each { |l| depfile.write(l + "\n") }
	softlines.each { |l| depfile.write(l + "\n") }
	toollines.each { |l| depfile.write(l + "\n") }
	depfile.close
	puts(".> Packing log file...")
	system("bzip2 " + @builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + ".strace." + ltype + ".log")
	## system("bzip2 " + @builddir + "/stage02/build/" + @pkg_name + "-" + @pkg_version + ".strace.install.log")
end
	
def find_deps_accessed(fnames)
	puts fnames.size.to_s + " files from stage02 found" 
	# lcount = 0
	# $stderr.puts "total: " + fnames.count.to_s 
	outlines = Array.new
	foundfiles = Array.new
	fnames.each { |f|
		# puts "checking: " + f
		resset = @sqlite.query("select fname, pkg_name, pkg_version, pkg_time from llfiles " + 
			" WHERE fname='" + SQLite3::Database.quote(f) + "' " +
			" AND ftype='f' AND stage='stage02' " +
			" AND pkg_time < " + @pkg_time.to_s + 
			" ORDER BY pkg_time desc limit(1)" )
		resset.each { |r|
			hardigno = "hard"
			hardigno = "igno" if f =~ /^\/usr\/lib\/pkgconfig(.*)\.pc$/ || f =~ /^\/usr\/share\/pkgconfig(.*)\.pc$/
			outstring = hardigno + "\t" + r[1] + "\t" + r[2] + "\t" + r[0]
			# puts outstring
			outlines.push outstring
			foundfiles.push f
		}
		# lcount += 1
		# printf lcount.to_s + " ... " if lcount % 50000 == 0 
	}
	return outlines # , foundfiles
end

def find_deps_tools(fnames)
	puts fnames.size.to_s + " files from stage01" 
	# lcount = 0
	# $stderr.puts "total: " + fnames.count.to_s 
	outlines = Array.new
	fnames.each { |f|
		# puts "checking: " + f
		resset = @sqlite.query("select fname, pkg_name, pkg_version, pkg_time from llfiles " + 
			" where fname='" + SQLite3::Database.quote(f) + 
			"' and ftype='f' and stage='stage01' order by pkg_time desc limit(1)" )
		resset.each { |r|
			outstring = "tool\t" + r[1] + "\t" + r[2] + "\t" + r[0]
			# puts outstring
			outlines.push outstring
		}
		# lcount += 1
		# printf lcount.to_s + " ... " if lcount % 50000 == 0 
	}
	return outlines
end

def find_deps_searched(fnames)
	allfiles = Array.new
	resset = @sqlite.query("select fname from llfiles " + 
		" where ftype='f' and stage='stage02' " )
	resset.each { |f| allfiles.push(f[0]) }
	files_to_check = fnames & allfiles
	puts files_to_check.size.to_s + " optional files from stage02" 
	# lcount = 0
	# $stderr.puts "total: " + fnames.count.to_s 
	outlines = Array.new
	files_to_check.each { |f|
		# puts "checking: " + f
		resset = @sqlite.query("select fname, pkg_name, pkg_version, pkg_time from llfiles " + 
			" where fname='" + SQLite3::Database.quote(f) + 
			"' and ftype='f' and stage='stage02' order by pkg_time desc limit(1)" )
		resset.each { |r|
			outstring = "soft\t" + r[1] + "\t" + r[2] + "\t" + r[0]
			# puts outstring
			outlines.push outstring
		}
		# lcount += 1
		# printf lcount.to_s + " ... " if lcount % 50000 == 0 
	}
	return outlines
end
	
def get_package_time
	pkg_time = 0
	resset = @sqlite.query("select distinct pkg_time from llfiles " + 
			" where pkg_name='" + SQLite3::Database.quote(@pkg_name) + "' AND " +
			" pkg_version='" + SQLite3::Database.quote(@pkg_version) + "' AND " +
			" stage='stage02' ORDER BY pkg_time desc limit(1)" )
	resset.each { |i| pkg_time = i[0].to_i }
	return pkg_time
end
	
@builddir = ARGV[0]
@pkg_name = ARGV[1]
@pkg_version = ARGV[2]
@sqlite = SQLite3::Database.new(@builddir + "/lesslinux.sqlite")
@pkg_time = get_package_time
@process_directory = Hash.new
@files_accessed = Array.new
@files_missing = Array.new

stracalyze("build")
stracalyze("install")



	