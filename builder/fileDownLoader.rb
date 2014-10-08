

class FileDownLoader

	@buildfile = nil
	@srcdir = nil
	@xfile = nil
	@dltokens = nil

	def initialize  (buildfile, srcdir, check_sources=true)
		# puts '-> parsing ' + buildfile
		puts sprintf("%015.4f", Time.now.to_f) + " info   > Parsing " + buildfile
		$stdout.flush
		@buildfile = buildfile
		@srcdir = srcdir
		@check_sources = check_sources 
		dltokens = []
		@xfile = REXML::Document.new(File.new(@buildfile))
		@xfile.elements.each("llpackages/package/sources/file") { |f|
			pkgname = f.elements["pkg"].text.strip
			shahash = f.elements["pkg"].attributes["sha1"]
			dllocations = Array.new
			f.elements.each("mirror") { |m| dllocations.push(m.text.strip) }
			dllocations = dllocations + [ "http://distfiles.lesslinux.org/", "http://distfiles.lesslinux.org/old/" ]
			srctoken = SingleSourceFile.new(@srcdir, pkgname, shahash, dllocations, @check_sources)
			dltokens.push(srctoken)
		}
		@dltokens = dltokens
	end

	def download
		@dltokens.each { |d| d.download }
	end
	

end