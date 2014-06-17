
class FileChecker
	
	def initialize (file_to_check, modtime, modtime_old, size, size_old, basepath, pkg_name, pkg_time, pkg_version, ftype, stage, dbh, sqlite, mahoro)
		@file_to_check = file_to_check.strip
		if file_to_check == ''
			@file_to_check  = '/'
		end
		@fullpath = basepath + "/" + file_to_check.strip
		@basepath = basepath
		@pkg_name = pkg_name
		@pkg_time = pkg_time
		@pkg_version = pkg_version
		@ftype = ftype
		@sha1sum = nil
		@size = size
		@size_old = size_old
		@modtime = modtime
		@modtime_old = modtime_old
		@file_output = ""
		@fmode = 0
		@uid = 0
		@gid = 0
		@dbh = dbh
		@sqlite = sqlite
		@stage = stage
		@mahoro = mahoro
		# @ftypes = REXML::Document.new(File.new("config/filetypes.xml"))
		@ftypes = nil
	end
	
	def save(fileout=nil)
		# Search for files with exact matches in name, size, modtime and type
		if @modtime_old.nil? || @modtime_old != @modtime || @size.to_i != @size_old.to_i
			return 0 if @file_to_check =~ /\/etc\/lesslinux\/pkglist.d\// 
			return 0 if @file_to_check =~ /\/var\/cache\/ldconfig\/aux-cache$/
			return 0 if @file_to_check =~ /\/etc\/ld\.so\.cache$/ 
			begin 
				if (@ftype == "f")
					@size = File.stat(@fullpath).size
				end
				@modtime = File.stat(@fullpath).mtime.to_i
				@fmode = sprintf("%o", File.stat(@fullpath).mode).to_i
				@uid = File.stat(@fullpath).uid
				@gid = File.stat(@fullpath).gid
			rescue
				puts '  -> softlink, destination not found?'
			end
			@file_type = nil
			if (@ftype == "f")
				fcont = nil 
				#ts = Time.now.to_f
				if @sha1sum.nil?
					begin
						fcont = File.read(@fullpath)
						@sha1sum = Digest::SHA1.hexdigest(fcont)
					rescue
						return 0
					end
				end
				# First: Try to take the file output from known files
				# resset = @sqlite.query("SELECT fileout FROM knownfiles WHERE fname = ? AND pkg_name = ?", 
				#	SQLite3::Database.quote(@file_to_check), SQLite3::Database.quote(@pkg_name) )
				# resset.each { |r| @file_output = r[0].strip }
				### puts "DEBUG: file output from database " + @file_output
				# Second: There might be a file output recorded in our XML, search for it
				$ovrrds.each { |r|
					if !r[3].nil? && r[4] =~  @file_to_check
						@file_output = r[3].strip 
					end
				}
				### puts "DEBUG: file output from XML " + @file_output
				# Third: Spawn a process
				if @file_output == ""
					## IO.popen("LC_ALL=POSIX file -F '::::' '" + @fullpath + "' | awk -F ':::: ' '{print $2}' ") { |f|
					##	@file_output = f.gets.strip
					## }
					fcont = File.read(@fullpath) if fcont.nil? 
					@file_output = @mahoro.buffer(fcont)
					puts sprintf("%015.4f", Time.now.to_f) + " debug  > Mahoro output #{@file_output}" 
					### puts "DEBUG: file output from file run  " + @file_output
				end
				rct = 0
				$foutputs.each { |r|
					rct += 1
					match = @file_output[r[0].strip]
					unless match.nil?
						@file_type = r[1].strip
					end
				}
				### puts "DEBUG: file type after comparing " + rct.to_s + " XML entries " + @file_type.to_s
				rct = 0
				$ovrrds.each { |r|
					rct += 1
					if r[4] =~  @file_to_check
						@file_type = r[1].strip 
					end
				}
				### puts "DEBUG: file type after comparing " + rct.to_s + " regexp " + @file_type.to_s
				puts sprintf("%015.4f", Time.now.to_f) + " check  > New/changed file " + @file_to_check 
				$stdout.flush
			end
			#ts = Time.now.to_f
			@sqlite.execute("INSERT INTO llfiles " + 
			" (fname, fsize, modtime, ftype, " + 
			" fowner, fgroup, fmode, sha1sum, " + 
			" file_output, pkg_name, pkg_version, " + 
			" pkg_time, stage, cleaned_type) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )", 
			[ SQLite3::Database.quote(@file_to_check), 
			SQLite3::Database.quote(@size.to_i.to_s), 
			SQLite3::Database.quote(@modtime.to_i.to_s), 
			SQLite3::Database.quote(@ftype), 
			SQLite3::Database.quote(@uid.to_s), 
			SQLite3::Database.quote(@gid.to_s), 
			SQLite3::Database.quote(@fmode.to_s), 
			SQLite3::Database.quote(@sha1sum.to_s), 
			SQLite3::Database.quote(@file_output.to_s), 
			SQLite3::Database.quote(@pkg_name), 
			SQLite3::Database.quote(@pkg_version), 
			SQLite3::Database.quote(@pkg_time.to_i.to_s), 
			SQLite3::Database.quote(@stage),
			SQLite3::Database.quote(@file_type.to_s)
			] ) 
			#puts("insert took " + (Time.now.to_f -  ts).to_s )
			#$stdout.flush
			return 1 if @ftype == "f"			
		end
		return 0
	end
	
	def read_all
		
	end
	
	def FileChecker.xml_to_database(xmlfile, sqlite)
		ftypes = REXML::Document.new(File.new(xmlfile))
		begin
			sqlite.execute("DROP TABLE pathoverrides;")
		rescue
		end
		begin
			sqlite.execute("DROP TABLE fileoutputs;")
		rescue
		end
		begin
			sqlite.execute("DROP TABLE knownfiles;")
		rescue
		end
		begin
			sqlite.execute("CREATE TABLE pathoverrides (id INTEGER PRIMARY KEY ASC, regexp TEXT, cleaned_type VARCHAR(256), sub_pkg VARCHAR(40));")
		rescue
		end
		begin
			sqlite.execute("CREATE TABLE fileoutputs (id INTEGER PRIMARY KEY ASC, fileout TEXT, cleaned_type VARCHAR(256), sub_pkg VARCHAR(40));")
		rescue
		end
		begin
			sqlite.execute("CREATE TABLE knownfiles (id INTEGER PRIMARY KEY ASC, pkg_name VARCHAR(80), pkg_version VARCHAR(40), fname TEXT, fileout TEXT);")
			sqlite.execute("CREATE INDEX known_idx ON knownfiles (fname ASC, pkg_name ASC) ")
		rescue
		end
		ftypes.elements.each("filetypes/pathoverride") { |t|
			t.elements.each("pathregexp") { |e|
				sqlite.execute("INSERT INTO pathoverrides " + 
					" (regexp, cleaned_type, sub_pkg) VALUES (?, ?, ?)",
					[ SQLite3::Database.quote(e.text.strip), 
					SQLite3::Database.quote(t.attributes["short"].to_s.strip), 
					SQLite3::Database.quote(t.attributes["subpackage"].to_s.strip) ]
				)
			}
		}
		ftypes.elements.each("filetypes/ftype") { |t|
			t.elements.each("fileout") { |e|
				sqlite.execute("INSERT INTO fileoutputs " + 
					" (fileout, cleaned_type, sub_pkg) VALUES (?, ?, ?)",
					[ SQLite3::Database.quote(e.text.strip), 
					SQLite3::Database.quote(t.attributes["short"].to_s.strip), 
					SQLite3::Database.quote(t.attributes["subpackage"].to_s.strip) ]
				)
			}
		}
	end
	
	def FileChecker.xml_to_overrides(xmlfile)
		ftypes = REXML::Document.new(File.new(xmlfile))
		ovrrds = Array.new
		ftypes.elements.each("filetypes/pathoverride") { |t|
			t.elements.each("pathregexp") { |e|
				fout = t.attributes["fileoutput"]
				fout = fout.strip unless fout.nil?
				ovrrds.push( [ e.text.strip, 
					t.attributes["short"].to_s.strip, 
					t.attributes["subpackage"].to_s.strip, 
					fout, 
					Regexp.new(e.text.strip) ] )
			}
		}
		return ovrrds 
	end
	
	def FileChecker.xml_to_foutputs(xmlfile)
		ftypes = REXML::Document.new(File.new(xmlfile))
		foutputs = Array.new
		ftypes.elements.each("filetypes/ftype") { |t|
			t.elements.each("fileout") { |e|
				foutputs.push( [ e.text.strip, t.attributes["short"].to_s.strip, t.attributes["subpackage"].to_s.strip ] )
			}
		}
		return foutputs
	end
	
	
end