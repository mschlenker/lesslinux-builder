

class PackageBuilder
	
	def initialize (basepath, pkg_name, pkg_version, dbh, sqlite, unstable=false)
		@basepath = basepath
		@pkg_name = pkg_name
		@pkg_version = pkg_version
		@dbh = dbh
		@sqlite = sqlite
		@pkg_time = 0
		@unstable = unstable
		resset = @sqlite.query("select distinct pkg_time from llfiles " + 
			" where pkg_name='" + SQLite3::Database.quote(@pkg_name) + "' AND " +
			" pkg_version='" + SQLite3::Database.quote(@pkg_version) + "' AND " +
			" stage='stage02' ORDER BY pkg_time desc limit(1)" )
		resset.each { |i| @pkg_time = i[0].to_i }
	end
	
	# An XML file with the description of the package does not exist, so 
	# we will create one that contains 
	
	def create_pkgdesc
		# Try to find an edited or old version first
		# Check for edited version, exact match in name and version
		# Check for edited version, fuzzy match in version
		#   => check for moved files, check for disappeared files, check for new files
		pfile = nil
		pfname = nil
		aux_version = nil
		aux_file = nil
		old_files = Hash.new
		old_dirs = Hash.new
		old_links = Hash.new
		old_info_newfiles = 0
		# version_match = false
		if File.exists?("scripts/pkg_content/" + @pkg_name + "-" + @pkg_version + ".xml" )
			if @unstable == true && File.exists?("scripts/pkg_content.unstable/" + @pkg_name + "-" + @pkg_version + ".xml" )
				pfile = REXML::Document.new(File.new("scripts/pkg_content.unstable/" + @pkg_name + "-" + @pkg_version + ".xml", "r"))
			else
				pfile = REXML::Document.new(File.new("scripts/pkg_content/" + @pkg_name + "-" + @pkg_version + ".xml", "r"))
			end
			pfname = @pkg_name + "-" + @pkg_version + ".xml"
			# version_match = true
		else
			Dir.foreach("scripts/pkg_content/") { |f|
				if (f =~ /.*\.xml$/  && f.index(@pkg_name) == 0 )
					puts '---> read ' + f
					aux_file = REXML::Document.new(File.new("scripts/pkg_content/" + f ))
					begin
						if ( aux_file.root.attributes["name"].strip == @pkg_name )
							version = aux_file.root.attributes["version"].strip
							if aux_version.nil?
								# $debug_messages.push("--> Found potential old version") 
								puts sprintf("%015.4f", Time.now.to_f) + " pkg    > Found potential old version!?"
								aux_version = PackageVersion.new(version)
								pfile = aux_file
								pfname = f
							elsif ( PackageVersion.new(version) > aux_version )
								aux_version = PackageVersion.new(version)
								pfile = aux_file
								pfname = f
							else
								aux_file = nil
							end
						end
					rescue
						# $debug_messages.push("--> No version info in " + f )
					end
					# ObjectSpace.garbage_collect
				end
			}
			ObjectSpace.garbage_collect
		end
		if !pfile.nil?
			pfile.elements.each("pkgdesc/subpackage") { |s|
				old_subpack = s.attributes["name"].strip
				unless old_files.has_key? old_subpack
					old_files[old_subpack] = Array.new
					old_dirs[old_subpack] = Array.new
					old_links[old_subpack] = Array.new
				end
				s.elements.each("file") { |l|
					# $debug_messages.push("  TEMP: adding key: " + old_subpack + " file: " + l.attributes["path"].strip)
					old_files[old_subpack].push(l.attributes["path"].strip)
				}
				s.elements.each("softlink") { |l|
					old_links[old_subpack].push(l.attributes["path"].strip)
				}
				s.elements.each("directory") { |l|
					old_dirs[old_subpack].push(l.attributes["path"].strip)
				}
			}
		end
		doc = REXML::Document.new
		doc.add_element("pkgdesc")
		doc.root.add_attribute("name", @pkg_name)
		doc.root.add_attribute("version", @pkg_version)
		skel = doc.root.add_element("subpackage")
		# Skeleton consists of directories and softlinks
		skel.add_attribute("name", "skel")
		# softlinks first
		#res = @dbh.query("SELECT DISTINCT fname, fowner, fgroup FROM llfiles WHERE ftype='l' " + 
		#	" AND pkg_name='" + @pkg_name + "' AND stage='stage02' AND pkg_version='" + @pkg_version + "' ")
		sqlite_res = @sqlite.query("SELECT DISTINCT fname, fowner, fgroup FROM llfiles WHERE ftype='l' " + 
			" AND pkg_name=? AND stage='stage02' AND pkg_version=? AND pkg_time=? ",
			[ SQLite3::Database.quote(@pkg_name), SQLite3::Database.quote(@pkg_version), @pkg_time.to_s ] )
		sqlite_res.each { |r|
			l = skel.add_element("softlink")
			l.add_attribute("path", r[0])
			l.add_attribute("owner", r[1])
			l.add_attribute("group", r[2])
		}
		# directories next
		#res = @dbh.query("SELECT DISTINCT fname, fowner, fgroup, fmode FROM llfiles WHERE ftype='d' " + 
		#	" AND pkg_name='" + @pkg_name + "' AND stage='stage02' AND pkg_version='" + @pkg_version + "' ")
		sqlite_res = @sqlite.query("SELECT DISTINCT fname, fowner, fgroup FROM llfiles WHERE ftype='d' " + 
			" AND pkg_name=? AND stage='stage02' AND pkg_version=?  AND pkg_time=? ",
			[ SQLite3::Database.quote(@pkg_name), SQLite3::Database.quote(@pkg_version), @pkg_time.to_s ] )
		sqlite_res.each { |r|
			l = skel.add_element("directory")
			l.add_attribute("path", r[0])
			l.add_attribute("owner", r[1])
			l.add_attribute("group", r[2])
			l.add_attribute("mode", r[3])
		}
		# Create nodes for subpackages
		spnodes = Hash.new
		[ "minimal", "bin", "doc", "config", "devel", "localization", "tzdata", "uncategorized", "ignore" ].each { |i|
			spnodes[i] = doc.root.add_element("subpackage")
			spnodes[i].add_attribute("name", i)
		}
		# Now identify cleaned_types and generate the nodes
		ctypes = REXML::Document.new(File.new("config/filetypes.xml"))
		ctype_subpack = Hash.new
		ctypes.elements.each("filetypes/pathoverride") { |t|
			unless t.attributes["subpackage"].nil?
				ctype_subpack[t.attributes["short"]] = t.attributes["subpackage"]
			end
		}
		ctypes.elements.each("filetypes/ftype") { |t|
			unless t.attributes["subpackage"].nil?
				ctype_subpack[t.attributes["short"]] = t.attributes["subpackage"]
			end
		}
		#res = @dbh.query("SELECT DISTINCT fname, fowner, fgroup, fmode, cleaned_type FROM llfiles WHERE ftype='f' " + 
		#	" AND pkg_name='" + @pkg_name + "' AND stage='stage02' AND pkg_version='" + @pkg_version + "' ")
		sqlite_res = @sqlite.query("SELECT DISTINCT fname, fowner, fgroup, fmode, cleaned_type, file_output FROM llfiles WHERE ftype='f' " + 
			" AND pkg_name=? AND stage='stage02' AND pkg_version=? AND pkg_time=? ",
			[ SQLite3::Database.quote(@pkg_name), SQLite3::Database.quote(@pkg_version), @pkg_time.to_s ] )
		sqlite_res.each { |r|
			old_info_found = false
			old_info_subpack = nil
			# $debug_messages.push("  TEMP: checking " + r[0] ) unless pfname.nil?
			old_files.each { |k, v|
				if v.include?(r[0])
					old_info_found = true
					old_info_subpack = k
				else
					# Count new files
					# old_info_newfiles += 1 
				end
			}
			if old_info_found
				# $debug_messages.push("  TEMP: found " + r[0] )
				n = spnodes[old_info_subpack].add_element("file")
				n.add_attribute("path", r[0])
				n.add_attribute("owner", r[1])
				n.add_attribute("group", r[2])
				n.add_attribute("mode", r[3])
				# n.add_attribute("fileout", r[5]) 
				old_files[old_info_subpack].delete(r[0])
			else
				# $debug_messages.push("  TEMP: not found " + r[0] ) unless pfname.nil?
				old_info_newfiles += 1 
				if spnodes.has_key?(ctype_subpack[r[4].to_s].to_s)
					n = spnodes[ctype_subpack[r[4].to_s]].add_element("file")
					n.add_attribute("path", r[0])
					n.add_attribute("owner", r[1])
					n.add_attribute("group", r[2])
					n.add_attribute("mode", r[3])
					# n.add_attribute("fileout", r[5]) 
				else
					n = spnodes["uncategorized"].add_element("file")
					n.add_attribute("path", r[0])
					n.add_attribute("owner", r[1])
					n.add_attribute("group", r[2])
					n.add_attribute("mode", r[3])
					# n.add_attribute("fileout", r[5]) 
				end
			end
		}
		old_files_vanished = 0
		vanished = doc.root.add_element("vanished")
		old_files.each { |k, v|
			# Find vanished files
			i = vanished.add_element("subpackage")
			i.add_attribute("name", k)
			v.each { |f|
				old_files_vanished += 1
				filenode = i.add_element("file")
				# $debug_messages.push("    vanished file " + f )
				puts sprintf("%015.4f", Time.now.to_f) + " pkg    > Vanished file? " + f 
				filenode.add_attribute("path", f)
			}
		}
		if (old_files_vanished > 0 || old_info_newfiles > 0) && !pfname.nil?
			puts sprintf("%015.4f", Time.now.to_f) + " pkg    > " + pfname + " Vanished files: " +  old_files_vanished.to_s
			puts sprintf("%015.4f", Time.now.to_f) + " pkg    > " + pfname + " New files:      " +  old_info_newfiles.to_s
		end	
		puts sprintf("%015.4f", Time.now.to_f) + " pkg    > Write pkg_content to " + @basepath + "/stage02/build/" + @pkg_name + "-" + @pkg_version + ".xml"
		$stdout.flush
		outfile = File.open(@basepath + "/stage02/build/" + @pkg_name + "-" + @pkg_version + ".xml", 'w')
		doc.write( outfile, 4)
		outfile.close
		# Force garbage collection
		pfile = nil
		aux_file = nil
		old_files = nil
		old_dirs = nil
		old_links = nil
		ObjectSpace.garbage_collect
	end
	
end

