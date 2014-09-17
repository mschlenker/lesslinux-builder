#!/usr/bin/ruby
# encoding: utf-8

require 'net/http'

server = 'free.avg.com'
path = '/de-de/download-free-all-product'

page = Net::HTTP.get(server, path)

exit 1 if page.nil? 

tarball = nil

ptoks = page.split
ptoks.each { |t|
	if t =~ /href\=\"(.*)\"$/
		url = $1
		if url =~ /flx(.*?)\.tar.gz$/ 
			puts url 
			tarball = url
		end
	end
}

exit 1 if tarball.nil? 

if system("mountpoint -q /lesslinux/blobpart") 
	if system("wget -O /lesslinux/blobpart/avg-free.tgz \"#{tarball}\"")
		system("ln -sf /lesslinux/blobpart/avg-free.tgz /lesslinux/blob/")
	else
		system("rm /lesslinux/blobpart/avg-free.tgz")
		exit 1
	end
else
	unless system("wget -O /lesslinux/blob/avg-free.tgz \"#{tarball}\"")
		system("rm /lesslinux/blob/avg-free.tgz")
		exit 1
	end
end

system("/etc/rc.d/0600-avg-antivirus.sh start") 
