#!/usr/bin/ruby
# encoding: utf-8

dlurl = "http://download.teamviewer.com/download/teamviewer_i386.tar.xz"

if system("mountpoint -q /lesslinux/blobpart") 
	if system("wget -O /lesslinux/blobpart/teamviewer_i386.tar.xz #{dlurl}")
		system("ln -sf /lesslinux/blobpart/teamviewer_i386.tar.xz /lesslinux/blob/")
	else
		system("rm /lesslinux/blobpart/teamviewer_i386.tar.xz")
		exit 1
	end
else
	unless system("wget -O /lesslinux/blob/teamviewer_i386.tar.xz #{dlurl}")
		system("rm /lesslinux/blob/teamviewer_i386.tar.xz")
		exit 1
	end
end

system("/etc/rc.d/0600-teamviewer.sh start") 
system("install -m 0755 /usr/share/applications/teamviewer.desktop /home/surfer/Desktop/")
system("chown surfer:surfer /home/surfer/Desktop/teamviewer.desktop") 
