#!/usr/bin/ruby
# encoding: utf-8

require "rexml/document"

tfile = ARGV[0]
outfile = ARGV[0].gsub(/\.xml$/, ".csv") 

@languages = Array.new
@stringids = Array.new 
@translations = Hash.new
doc = REXML::Document.new File.new(tfile)
doc.elements.each("lltranslation/language") { |l|
	@languages.push l.attributes["id"]  
	@translations[l.attributes["id"] ] = Hash.new
	l.elements.each("string") { |s|
		@translations[l.attributes["id"] ][s.attributes["id"] ] = s.attributes["translation"] 
		@stringids.push s.attributes["id"] 
	}
}

@languages.each { |l|
	#puts l 
}
@stringids.uniq.each { |i|
	#puts i 
}
@translations.each { |k,v|
	#puts "#{k}: #{v.to_s}"
}


outh = File.new(outfile, "w") 

outh.print "\"\";"
@languages.each { |l|
	outh.print "\"#{l}\";"
}
outh.print "\n"
@stringids.each { |s|
	outh.print "\"#{s}\";"
	@languages.each { |l|
		begin
			escpd = @translations[l][s].gsub('"', '""')
		rescue
			escpd = "" 
		end
		outh.print "\"#{escpd}\";"
	}
	outh.print "\n"
}