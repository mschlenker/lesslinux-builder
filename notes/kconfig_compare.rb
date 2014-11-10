#!/usr/bin/ruby
# encoding: utf-8

optversions = Hash.new
[ ARGV[0], ARGV[1] ].each { |f|
	optversions[f] = Hash.new
	File.open(f).each { |line|
		# puts line 
		option = nil
		if line =~ /is not set/
			# puts line
			ltoks = line.strip.split
			# puts ltoks[1] 
			option = ltoks[1].gsub("CONFIG_", "")
			optversions[f][option] = "n"
		elsif line =~ /^CONFIG_/ 
			# puts line
			ltoks = line.strip.split("=")
			option = ltoks[0].gsub("CONFIG_", "")
			value = ltoks[1] 
			optversions[f][option] = value
			# puts "#{option} = #{ltoks[1]}" unless ( ltoks[1] == "m" ||  ltoks[1] == "y" )
		end
	}
	optversions[f].each { |k,v|
		# puts "KEY: #{k}, VAL: #{v}" 
	}
}

# Find options in one kernel, but not in the other
# only left
# puts optversions[ ARGV[1] ].keys.to_s 
# puts optversions[ ARGV[0] ].keys.size
# puts optversions[ ARGV[1] ].keys.size

unless ARGV[2].nil?
	dump = File.new(ARGV[2], "w") 
end

puts "<== parameters only left in #{ARGV[0]}"
# puts ( optversions[ ARGV[0] ].keys.sort - optversions[ ARGV[1] ].keys.sort ).to_s 
( optversions[ ARGV[0] ].keys - optversions[ ARGV[1] ].keys ).sort.each { |k|
	out = nil 
	if optversions[ ARGV[0] ][k] == "n" 
		out = "# CONFIG_#{k} is not set"
		puts out
	else
		out = "CONFIG_#{k}=" + optversions[ ARGV[0] ][k]
		puts out
	end
	unless ( out.nil? || ARGV[2].nil? ) 
		dump.write(out + "\n") 
	end
}
puts "==> parameters only right in #{ARGV[1]}"
( optversions[ ARGV[1] ].keys - optversions[ ARGV[0] ].keys ).sort.each { |k|
	# puts "#{k} only right" 
	if optversions[ ARGV[1] ][k] == "n" 
		puts "# CONFIG_#{k} is not set"
	else
		puts "CONFIG_#{k}=" + optversions[ ARGV[1] ][k]
	end
}

diffcount = 0 
puts "<==> different parameters #{ARGV[0]} vs. #{ARGV[1]}"
( optversions[ ARGV[1] ].keys & optversions[ ARGV[0] ].keys ).sort.each { |k|
	unless optversions[ ARGV[1] ][k] == optversions[ ARGV[0] ][k]
		diffcount += 1
		puts "CONFIG_#{k} #{optversions[ ARGV[0] ][k]} vs. #{optversions[ ARGV[1] ][k]}"
	end
}
puts "#{diffcount} differences" 

