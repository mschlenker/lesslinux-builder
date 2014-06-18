#!/usr/bin/ruby
# encoding: utf-8

require "tmpdir"

class MfsRegistryDatabase
	
	def initialize(partition, path)
		@partition = partition
		@regfile = path
		@samusers = nil
	end
	
	attr_reader :partition, :regfile 
	
	def get_shell
		was_mounted = true
		if @partition.mount_point.nil?
			was_mounted = false
			@partition.mount
		end
		puts @partition.mount_point[0] 
		mnt = @partition.mount_point 
		valid_reg = system('echo -e "q\n" | chntpw -e \'' + mnt[0] + "/" + @regfile + "'") 
		return nil if valid_reg == false
		lcount = 0
		nline = -1
		shell = nil
		IO.popen("printf \"cat Microsoft\\Windows NT\\CurrentVersion\\Winlogon\\Shell\\nq\\n\" | chntpw -e '" + mnt[0] + "/" + @regfile + "'"  ) { |l| 
			while l.gets
				nline = lcount if $_ =~ /currentversion.winlogon.shell/i 
				shell = $_.strip if lcount == nline + 1  
				lcount += 1
			end
		}
		@partition.umount if was_mounted == false
		return shell
	end
	
	def shell_is_explorer?
		current_shell = get_shell
		return nil if current_shell.nil?
		return true if current_shell =~ /explorer\.exe/i 
		return false
	end
	
	def reset_shell(backup=false)
		aux = shell_is_explorer?
		return nil if aux.nil?
		return true if aux == true
		was_mounted = true
		if @partition.mount_point.nil?
			was_mounted = false
			@partition.mount
		end
		return false unless @partition.remount_rw
		puts @partition.mount_point[0] 
		mnt = @partition.mount_point
		if backup == true
			now = Time.new.to_i
			return false unless system("cp '#{@partition.mount_point[0]}/#{@regfile}' '#{@partition.mount_point[0]}/#{@regfile}.#{now.to_s}'") 
		end
		cmd = "printf \"cd Microsoft\\Windows NT\\CurrentVersion\\Winlogon\\ncat Shell\\ned Shell\\nexplorer.exe\\ncat Shell\\nq\\ny\\n\" | chntpw -e '" + mnt[0] + "/" + @regfile + "'"
		puts "RUNNING: #{cmd}"
		system(cmd) 
		retval = $?.exitstatus
		$stderr.puts "RETURNED: " + retval.to_s
		return true if retval == 2
		return false
		# return success 
	end

end