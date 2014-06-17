
class PackageVersion
	
	include Comparable
	
	def initialize (version_string)
		@vers_string = version_string
		@vers_array = @vers_string.split(".")
	end

	def to_s
		return @vers_string
	end
	
	def <=> (another)
		other_array = another.to_s.split(".")
		0.upto( [@vers_array.size, other_array.size].max - 1 ) { |i|
			if @vers_array[i].nil? && !other_array[i].nil?
				return -1
			end
			if !@vers_array[i].nil? && other_array[i].nil?
				return 1
			end
			if (compare_segment(@vers_array[i], other_array[i]) != 0 )
				return compare_segment(@vers_array[i], other_array[i])
			end
		}
		return 0
	end

	def compare_segment (myseg, otherseg)
		# Compare number first
		# $stderr.puts "Comparing " + myseg.to_s + " with " + otherseg.to_s
		if (myseg.to_i > otherseg.to_i)
			return 1
		end
		if (myseg.to_i < otherseg.to_i)
			return -1
		end
		# compare strings
		if (myseg.to_s.downcase > otherseg.to_s.downcase)
			return 1
		end
		if (myseg.to_s.downcase < otherseg.to_s.downcase)
			return -1
		end
		return 0
	end
	
end