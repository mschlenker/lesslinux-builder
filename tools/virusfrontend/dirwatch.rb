#!/usr/bin/ruby
# encoding: utf-8

require 'rb-inotify'
notifier = INotify::Notifier.new
notifier.watch(ARGV[0], :close_write) { |event|
	system("ruby /usr/share/lesslinux/avfrontend/autoscan.rb \"#{ARGV[0]}/#{event.name}\"")
}
notifier.run
