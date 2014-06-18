#!/usr/bin/ruby
# encoding: utf-8

def read_temp(kill=true)
		cputemp = 0
		critical = 80
		lcount = 0
		cpuline = -1
		IO.popen("sensors") { |line|
			while line.gets 
				# CPU Temperature:    +49.0°C  (high = +60.0°C, crit = +95.0°C)
				# temp1: +70.0°C (crit = +92.0°C)
				# 
				# temp1: +44.8°C (high = +70.0°C)
				#                (crit = +100.0°C, hyst = +97.0°C) 
				if $_ =~ /cpu temperature.*?\+(\d+)\.\d°C.*?crit.*?(\d+)\.\d°C/i 
					puts "Core: " + $1
					puts "Crit: " + $2
					cputemp = $1.to_i 
					critical = $2.to_i 
				elsif $_ =~ /^temp\d.*?\+(\d+)\.\d°C.*?crit.*?(\d+)\.\d°C/i 	
					puts "Core: " + $1
					puts "Crit: " + $2
					cputemp = $1.to_i 
					critical = $2.to_i
				elsif $_ =~ /^temp\d.*?\+(\d+)\.\d°C.*?high.*?(\d+)\.\d°C/i 
					puts "Core: " + $1
					puts "High: " + $2
					cpuline = lcount
					cputemp = $1.to_i
				elsif  lcount - cpuline == 1 
					puts $_
					if $_ =~ /^\s*\(.*?crit.*?(\d+)\.\d°C/i 
						puts "Crit: " + $1
						critical = $1.to_i
					end
				end
				lcount += 1
			end
			if critical - cputemp < 6 && kill == true
				system("killall -9 cpuburn")
			end
		}
		return cputemp, critical
end

sensors_found = false

IO.popen("sensors") { |line|
	while line.gets
		sensors_found = true if $_ =~ /cpu temperature.*?\+(\d+)\.\d°C.*?crit.*?(\d+)\.\d°C/i 
		sensors_found = true if $_ =~ /temp\d.*?\+(\d+)\.\d°C.*?crit.*?(\d+)\.\d°C/i 	
		sensors_found = true if $_ =~ /temp\d.*?\+(\d+)\.\d°C.*?high.*?(\d+)\.\d°C/i 
	end
}

exit 1 if sensors_found == false

0.upto(60) { |n|
	cputemp, critical = read_temp(false) 
	if critical - cputemp < 6
		system("touch /var/run/lesslinux/cpuburn.failed")
		system("killall -9 cpuburn") 
		exit 1 
	end
	sleep 1.0
}

system("killall -9 cpuburn") 
exit 0

