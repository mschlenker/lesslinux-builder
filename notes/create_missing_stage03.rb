#!/usr/bin/ruby
# encoding: utf-8

require "rexml/document"

# traverse all stable stage03 scripts

@pkgnames = Array.new
Dir.foreach("scripts/stage03") { |f|
	if f =~ /^[0-9][0-9][0-9][0-9].*?\.xml$/ 
		puts f 
		x = REXML::Document.new(File.new("scripts/stage03/" + f))
		pkg_name = x.elements["llpackages/package"].attributes["name"]
		@pkgnames.push pkg_name
	end
}

File.open(ARGV[0]).each { |line|
	unless line.strip =~ /^#/ || line.strip =~ /^$/
		if @pkgnames.include?(line.strip)
			puts "FOUND:   #{line}"
		else
			puts "MISSING: #{line}" 
			of = File.new("scripts/stage03/6667_" + line.strip + ".xml", "w")
			of.write("<llpackages><package name=\"#{line.strip}\" /></llpackages>\n")
			of.close
		end
	end
}