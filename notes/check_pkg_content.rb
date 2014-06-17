#!/usr/bin/ruby
# encoding: utf-8

require "rexml/document"

# traverse all stable stage02 scripts

@stablexml = Hash.new
@filenames = Hash.new
Dir.foreach("scripts/stage02") { |f|
	if f =~ /^[0-9][0-9][0-9][0-9].*?\.xml$/ 
		x = REXML::Document.new(File.new("scripts/stage02/" + f))
		pkg_name = x.elements["llpackages/package"].attributes["name"]
		pkg_version = x.elements["llpackages/package"].attributes["version"]
		@stablexml[pkg_name] = pkg_version 
		@filenames[pkg_name] = f
	end
}

# traverse all unstable stage02 scripts

@unstablexml = Hash.new
Dir.foreach("scripts/stage02.unstable") { |f|
	if f =~ /^[0-9][0-9][0-9][0-9].*?\.xml$/ 
		x = REXML::Document.new(File.new("scripts/stage02.unstable/" + f))
		pkg_name = x.elements["llpackages/package"].attributes["name"]
		pkg_version = x.elements["llpackages/package"].attributes["version"]
		@unstablexml[pkg_name] = pkg_version 
	end
}

# traverse all stable pkg_content 

@pkgcontent = Array.new 
Dir.foreach("scripts/pkg_content") { |f| @pkgcontent.push f  if f =~ /\.xml$/  }
Dir.foreach("scripts/pkg_content.unstable") { |f| @pkgcontent.push f  if f =~ /\.xml$/  }
	
@unstablexml.each { |k,v|
	if @stablexml.has_key?(k) 
		if v == @stablexml[k] 
			# puts "#{k} Versions in stage02 and stage02.unstable match"
		else
			# puts "#{k} Versions in stage02 and stage02.unstable differ"
			if @pkgcontent.include?("#{k}-#{@stablexml[k] }.xml")
				puts "#{@filenames[k]} - #{k} #{@stablexml[k] } vs. #{v} matching pkg_content for stable stage02, but not for unstable" unless  @pkgcontent.include?("#{k}-#{v}.xml")
			end
		end
	end
}