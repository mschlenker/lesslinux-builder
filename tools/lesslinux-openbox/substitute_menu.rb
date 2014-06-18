#!/usr/bin/ruby
# encoding: utf-8

require "rexml/document"
translations = Hash.new

target = ENV["LANGUAGE"][0..1]
target = "en" if target.nil? 
infile = ARGV[0]
outfile = ARGV[1]
transfile = ARGV[2] 

doc = REXML::Document.new File.new(transfile)
en = doc.elements["/lltranslation/language[@id='en']"]
en.elements.each("string") { |s|
	translations[ s.attributes["id"] ] = s.attributes["translation"]
}
tgt = doc.elements["/lltranslation/language[@id='#{target}']"]
unless tgt.nil?
	tgt.elements.each("string") { |s|
		translations[ s.attributes["id"] ] = s.attributes["translation"]
	}
end

out = File.new(outfile, "w")
File.open(infile).each { |line|
	outline = line
	translations.each { |k,v| outline = outline.gsub(k, v) }
	out.write(outline)
}
out.close
