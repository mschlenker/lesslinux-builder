#!/usr/bin/ruby
# encoding: utf-8

dlurl = "http://downloadeu1.teamviewer.com/download/teamviewer_linux.tar.gz"

if system("mountpoint -q /lesslinux/blobpart") 
	if system("wget -O /lesslinux/blobpart/teamviewer_linux.tar.gz #{dlurl}")
		system("ln -sf /lesslinux/blobpart/teamviewer_linux.tar.gz /lesslinux/blob/")
	else
		system("rm /lesslinux/blobpart/teamviewer_linux.tar.gz")
		exit 1
	end
else
	unless system("wget -O /lesslinux/blob/teamviewer_linux.tar.gz #{dlurl}")
		system("rm /lesslinux/blob/teamviewer_linux.tar.gz")
		exit 1
	end
end

system("/etc/rc.d/0600-teamviewer.sh start") 
system("install -m 0755 /usr/share/applications/teamviewer.desktop /home/surfer/Desktop/")
system("chown surfer:surfer /home/surfer/Desktop/teamviewer.desktop") 
