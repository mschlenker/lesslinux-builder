#!/usr/bin/ruby
# encoding: utf-8

require 'MfsDiskDrive'
require 'MfsSinglePartition'
require 'XmlDriveList'
require "rexml/document"

x = XmlDriveList.new
x.dump_xml
