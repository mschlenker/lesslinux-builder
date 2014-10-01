#!/usr/bin/ruby
# encoding: utf-8

dlurl = "https://dl.google.com/linux/direct/google-chrome-stable_current_i386.deb"

if system("mountpoint -q /lesslinux/blobpart") 
	if system("wget -O /lesslinux/blobpart/google-chrome-stable_current_i386.deb #{dlurl}")
		system("ln -sf /lesslinux/blobpart/google-chrome-stable_current_i386.deb /lesslinux/blob/")
	else
		system("rm /lesslinux/blobpart/google-chrome-stable_current_i386.deb")
		exit 1
	end
else
	unless system("wget -O /lesslinux/blob/google-chrome-stable_current_i386.deb #{dlurl}")
		system("rm /lesslinux/blob/google-chrome-stable_current_i386.deb")
		exit 1
	end
end

system("/etc/rc.d/0600-google-chrome.sh start") 
system("install -m 0755 /usr/share/applications/google-chrome.desktop /home/surfer/Desktop/")
system("chown surfer:surfer /home/surfer/Desktop/google-chrome.desktop") 