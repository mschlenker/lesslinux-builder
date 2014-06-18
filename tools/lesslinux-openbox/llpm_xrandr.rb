#!/usr/bin/ruby
# encoding: utf-8

require "rexml/document"

class RandResolution
	include Comparable
	def initialize(width, height)
		@width = width
		@height = height
	end
	attr_reader :width, :height
	def to_s
		return @width.to_s + "x" + @height.to_s 
	end
	def <=>(oth)
		return 1 if oth.width > @width
		return 1 if oth.height > @height && oth.width == @width
		return -1 if oth.width < @width
		return -1 if oth.height < @height && oth.width == @width
		return 0
	end
end

resolutions = Array.new 
common_res = [
	RandResolution.new(1920, 1200),
	RandResolution.new(1920, 1080),
	RandResolution.new(1680, 1050),
	RandResolution.new(1600, 1200),
	RandResolution.new(1440, 900),
	RandResolution.new(1400, 1050),
	RandResolution.new(1366, 768),
	RandResolution.new(1280, 1024),
	RandResolution.new(1280, 800),
	RandResolution.new(1280, 768),
	RandResolution.new(1280, 720),
	RandResolution.new(1152, 864),
	RandResolution.new(1024, 768),
	RandResolution.new(1024, 600),
	RandResolution.new(800, 600),
	RandResolution.new(800, 480),
	RandResolution.new(640, 480),
]
selected = nil
doc = REXML::Document.new # (nil, { :respect_whitespace => %w{ script style } } )
root = REXML::Element.new "openbox_pipe_menu"

IO.popen("xrandr") { |l|
	while l.gets
		if $_.strip =~ /^[0-9]/
			ltoks = $_.strip.split
			resolutions.push(RandResolution.new(ltoks[0].split("x")[0].to_i, ltoks[0].split("x")[1].to_i))
			selected = RandResolution.new(ltoks[0].split("x")[0].to_i, ltoks[0].split("x")[1].to_i) if ltoks[1] =~ /\*$/ 
		end
	end
}

rescount = 0
resarray = Array.new

resolutions.sort.each { |r|
	if common_res.include?(r)
		rescount += 1
		label = r.to_s
		label = r.to_s + " *" if r == selected
		item = REXML::Element.new "item"
		item.add_attribute("label", label)
		action = REXML::Element.new "action"
		action.add_attribute("name", "Execute")
		command = REXML::Element.new "command"
		# command.add_text "xrandr --size #{r.to_s}"
		command.add_text "xrandrwrap #{r.to_s}"
		item.add_element action
		action.add_element command
		resarray.push item 
		# root.add_element item
	end
}

unless common_res.include?(selected)
	unless selected.nil? 
		rescount += 1
		label = selected.to_s + " *"
		item = REXML::Element.new "item"
		item.add_attribute("label", label)
		action = REXML::Element.new "action"
		action.add_attribute("name", "Execute")
		command = REXML::Element.new "command"
		# command.add_text "xrandr --size #{selected.to_s}"
		command.add_text "xrandrwrap #{selected.to_s}"
		item.add_element action
		action.add_element command 
		resarray = [ item ]
	end
end

if rescount < 2 
	label = "Resolution cannot be changed"
	item = REXML::Element.new "item"
	item.add_attribute("label", label)
	action = REXML::Element.new "action"
	action.add_attribute("name", "Execute")
	command = REXML::Element.new "command"
	command.add_text "/bin/true"
	item.add_element action
	action.add_element command 
	resarray = [ item ]
end

resarray.each { |i| root.add_element i }

doc.add root
doc.write($stdout, 4)
