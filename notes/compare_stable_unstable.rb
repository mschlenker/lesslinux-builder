#!/usr/bin/ruby

stable_scripts = []
unstable_scripts = []

Dir.entries("scripts/stage02").each { |f|
	stable_scripts.push f if f =~ /\.xml$/
}
Dir.entries("scripts/stage02.unstable").each { |f|
	unstable_scripts.push f if f =~ /\.xml$/
}
missing_scripts = stable_scripts - unstable_scripts
missing_scripts.each { |f|
	puts f
}