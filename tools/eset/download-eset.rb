#!/usr/bin/ruby
# encoding: utf-8

require 'fileutils'
dlurl = 'https://download.eset.com/com/eset/tools/recovery/rescue_cd/latest/eset_sysrescue_live_enu.iso'
# dlurl = "https://download.eset.com/com/eset/tools/recovery/rescue_cd/latest/eset-sysrescue.1.0.9.0.enu.iso"

if system("mountpoint -q /lesslinux/blobpart") 
	FileUtils.mkdir_p("/lesslinux/blobpart/eset")
	unless system("wget -O /lesslinux/blobpart/eset/eset.iso #{dlurl}")
		system("rm /lesslinux/blobpart/eset/eset.iso")
		exit 1
	end
else
	FileUtils.mkdir_p("/lesslinux/blob/eset")
	unless system("wget -O /lesslinux/blob/eset/eset.iso #{dlurl}")
		system("rm /lesslinux/blob/eset/eset.iso")
		exit 1
	end
end

system("/etc/rc.d/0611-eset.sh start") 

