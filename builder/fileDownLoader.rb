

class FileDownLoader

	@buildfile = nil
	@srcdir = nil
	@xfile = nil
	@dltokens = nil
	@mirror = nil 

	def initialize  (buildfile, srcdir, check_sources=true, mirror=nil)
		puts sprintf("%015.4f", Time.now.to_f) + " info   > Parsing " + buildfile
		$stdout.flush
		@buildfile = buildfile
		@srcdir = srcdir
		@check_sources = check_sources 
		@mirror = mirror 
		dltokens = []
		@xfile = REXML::Document.new(File.new(@buildfile))
		@xfile.elements.each("llpackages/package/sources/file") { |f|
			pkgname = f.elements["pkg"].text.strip
			shahash = f.elements["pkg"].attributes["sha1"]
			dllocations = Array.new
			dllocations.push(@mirror) unless @mirror.nil? 
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