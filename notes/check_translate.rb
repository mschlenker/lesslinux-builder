#!/usr/bin/ruby
# encoding: utf-8

require "rexml/document"

fname = ARGV[0]
tfile = ARGV[1] 
@occurencies = Hash.new
@missing = 0 
lnum = 1
File.open(fname).each { |line|
	ltoks = line.strip.split
	ltoks.each { |w|
		if w =~ /get_translation\(\"(.*?)\"\)/ || w =~ /get_translation\s+\"(.*?)\"/
			str = $1
			# puts "#{lnum}: #{str}"
			@occurencies[str] = Array.new unless @occurencies.has_key? str
			@occurencies[str].push lnum 
		end
	}
	lnum +=1
}
@translations = Hash.new
doc = REXML::Document.new File.new(tfile)
doc.elements.each("lltranslation/language") { |l|
	@translations[l.attributes["id"] ] = Array.new
	l.elements.each("string") { |s|
		@translations[l.attributes["id"] ].push s.attributes["id"] 
	}
}

@translations.each { |k,v|
	# puts "#{k}: #{v.join(' ')}"
}
@occurencies.each { |k,v|	
	z = v.map { |x| x.to_s } 
	# puts "#{k}: #{z.join(' ')}"
}
@occurencies.keys.sort.each { |k|
	@translations.each { |l,s|
		unless s.include?(k)
			v = @occurencies[k].map { |x| x.to_s } 
			puts "#{l} - Missing translation for \"#{k}\" occurs: #{v.join(' ')}"
			@missing += 1
		end
	}
}
puts "#{@missing.to_s} missing translations" 