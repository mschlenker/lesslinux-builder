#!/usr/bin/ruby

require 'rexml/document'

archive = ARGV[0]
output = nil
if ARGV[1].nil? 
	output = $stderr
else
	output = File.new(ARGV[1], "w")
end
now = Time.now.strftime("%Y%m%d")
dircount = 0
pkgname = nil
pkgversion = nil
buildtype = nil
subdir = nil

if archive.nil? || archive == "" 
	$stderr.puts "Please provide an URL!"
	exit 1
end

uuid = ` uuidgen `.strip 

Dir.mkdir "/tmp/#{uuid}"
Dir.mkdir "/tmp/#{uuid}/unpack"

# Download the archive
$stderr.puts "Trying to download #{archive} to /tmp/#{uuid}"
archname = archive.split("/")[-1] 

# Try to determine pkg_name and pkg_version
if archname =~ /(.*)\-([[0-9]\.]*)\.tar/ || archname =~ /(.*)\-([[0-9]\.]*)\.zip/
	pkgname = $1
	pkgversion = $2
	$stderr.puts "package name:    #{pkgname}"
	$stderr.puts "package version: #{pkgversion}"
end
pkgversion = now if pkgversion.nil?

system("wget -O /tmp/#{uuid}/#{archname} #{archive}")
unless File.exists? "/tmp/#{uuid}/#{archname}"
	$stderr.puts "Download failed!"
	exit 1
end

# Create the SHA1SUM
sha1sum = `sha1sum /tmp/#{uuid}/#{archname}`.strip.split[0] 

# Unpack the archive 
# FIXME: Unzip zip as well 
if archname =~ /\.tar.bz2$/ || archname =~ /\.tar.gz$/ || archname =~  /\.tar.xz$/
	system(" tar -C /tmp/#{uuid}/unpack -xf /tmp/#{uuid}/#{archname}")
else
	$stderr.puts "This type of archive is not (yet) supported!"
	exit 1
end

# Make sure only one directory is created
Dir.entries("/tmp/#{uuid}/unpack").each { |d|
	unless d == "." || d == ".."
		if File.directory?("/tmp/#{uuid}/unpack/#{d}") 
			dircount += 1 
			subdir = d
		end
	end
}

# Check if package is python or normal configure or autogen
# FIXME: Eventually check for perl ruby and cmake as well
if dircount == 1
	if File.exists?("/tmp/#{uuid}/unpack/#{subdir}/configure")
		buildtype = "configure"
	elsif File.exists?("/tmp/#{uuid}/unpack/#{subdir}/setup.py")
		buildtype = "python"
	elsif File.exists?("/tmp/#{uuid}/unpack/#{subdir}/autogen.sh")
		buildtype = "autogen"
	end
end

# Now create an XML structure

doc = REXML::Document.new
llpack = doc.add_element("llpackages")
package = llpack.add_element("package")
if pkgname.nil? 
	package.add_attribute("name", archname)
else
	package.add_attribute("name", pkgname)
end
package.add_attribute("version", pkgversion)
package.add_attribute("install", "chroot")
lic = package.add_element("license")
lic.text = "unknown"
src = package.add_element("sources")
file = src.add_element("file")
pkg = file.add_element("pkg")
pkg.add_attribute("sha1", sha1sum)
pkg.text = archname 
mirror = file.add_element("mirror")
mirror.text = archive.gsub(archname, "")
mancheck = src.add_element("manualcheck")
mancheck.add_attribute("date", now)
mancheck.add_attribute("interval", "60")
mancheck.add_attribute("mirror", archive.gsub(archname, ""))
unpack = package.add_element("unpack")
patch = package.add_element("patch")
build = package.add_element("build")
install = package.add_element("install")
clean = package.add_element("clean")
chdir = nil
unless pkgname.nil? 
	unpack.add(REXML::CData.new("tar xf ${SRCDIR}/" + archname.gsub(pkgname, "${PKGNAME}").gsub(pkgversion, "${PKGVERSION}") + "\n"))
	clean.add(REXML::CData.new("rm -rf " + subdir.gsub(pkgname, "${PKGNAME}").gsub(pkgversion, "${PKGVERSION}") + "\n"))
	chdir = "cd " + subdir.gsub(pkgname, "${PKGNAME}").gsub(pkgversion, "${PKGVERSION}")
else
	unpack.add(REXML::CData.new("tar xf " + archname + "\n"))
	clean.add(REXML::CData.new("rm -rf " + subdir + "\n"))
	chdir = "cd " + subdir
end
buildcommand = [ chdir ]
installcommand = [ chdir ]
if buildtype == "python"
	[ "config", "build" ].each { |c|
		buildcommand.push("python setup.py #{c}")
	}
	installcommand.push("python setup.py install")
elsif buildtype == "configure" || buildtype == "autogen"
	buildcommand.push("bash autogen.sh") if buildtype == "autogen"
	buildcommand.push("./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var")
	buildcommand.push("make")
	installcommand.push("make install")
end
[ buildcommand, installcommand ].each { |c| c.push("") }
build.add(REXML::CData.new(buildcommand.join("\n")))
install.add(REXML::CData.new(installcommand.join("\n")))

doc.write( output, 4 )
$stderr.puts("Please remove /tmp/#{uuid}")










