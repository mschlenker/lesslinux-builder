

class SingleSourceFile
	
	@srcdir = nil
	@filename = nil
	@shahash = nil
	@dllocations = []
	@hash_matches = false
	
	def initialize (srcdir, filename, shahash, dllocations, check_sources=true)
		@srcdir = srcdir
		@filename = filename
		@shahash = shahash
		@dllocations = dllocations
		@check_sources = check_sources
	end
	
	def download
		check_hash
		if (@hash_matches == true)
			puts "-> package " + @filename + " already exists, not downloading!"
		else
			@dllocations.each { |i|
				unless (@hash_matches == true) 
					get_file(i)
					check_hash
				end
			}
		end
		unless (@hash_matches == true)
			puts "=> could not download " +  @filename  + " - please check!"
			raise "FileNotFound"
		end
	end
	
	def get_file(location)
		system("wget --no-check-certificate -O '" + @srcdir.strip.gsub(/\/$/, "") + "/" + @filename + "' '" + location.strip.gsub(/\/$/, "") + "/" + @filename + "'")  unless system("wget -O '" + @srcdir.strip.gsub(/\/$/, "") + "/" + @filename + "' '" + location.strip.gsub(/\/$/, "") + "/" + @filename + "'") 
	end
	
	def check_hash
		if File.exists?(@srcdir + "/" + @filename)
			if @check_sources == false
				@hash_matches = true
				return true 
			end
			tmphash = Digest::SHA1.hexdigest(File.read(@srcdir + "/" + @filename))
			if tmphash == @shahash
				puts '-> checksum matches, looks good'
				@hash_matches = true
			else
				puts '-> checksum does not match, move file'
				File.rename(@srcdir + "/" + @filename, @srcdir + "/" + @filename + ".corrupt." + Time.new.to_i.to_s)
			end
		end	
	end

	def cleanup
		
	end

end