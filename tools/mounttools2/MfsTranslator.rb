#!/usr/bin/ruby
# encoding: utf-8

require "rexml/document"

class MfsTranslator
	def initialize(lang, file)
		@language = lang
		@translations = Hash.new
		doc = REXML::Document.new File.new(file)
		en = doc.elements["/lltranslation/language[@id='en']"]
		en.elements.each("string") { |s|
			@translations[ s.attributes["id"] ] = s.attributes["translation"]
		}
		tgt = doc.elements["/lltranslation/language[@id='#{@language}']"]
		unless tgt.nil?
			tgt.elements.each("string") { |s|
				@translations[ s.attributes["id"] ] = s.attributes["translation"]
			}
		end
	end
	attr_reader :translations
	def get_translation(string_id)
		trans = @translations[string_id]
		if trans.nil?
			return string_id
		else
			return trans
		end
	end
end
