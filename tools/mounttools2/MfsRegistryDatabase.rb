#!/usr/bin/ruby
# encoding: utf-8

require "tmpdir"
require "hivex"

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
		mnt = @partition.mount_point 
		h = Hivex::open(mnt[0] + "/" + @regfile, {})
		root = h.root()
		node = h.node_get_child(root, "Microsoft")
		if node.nil?
			$stderr.puts "no HKLM\\SOFTWARE\\Microsoft node: Probably not the correct hive"
			return nil
		end
		node = h.node_get_child(node, "Windows NT")
		node = h.node_get_child(node, "CurrentVersion")
		node = h.node_get_child(node, "Winlogon")
		val = h.node_get_value(node, "Shell")
		hash = h.value_value(val)
		shell = hash[:value].to_s.gsub("\x00", "").strip 
		# shell.encode!("UTF-8", "UTF-8", { :invalid => :replace } )
		@partition.umount if was_mounted == false
		$stderr.puts "Found shell: #{shell} #{shell.encoding}"
		h.close
		return shell
	end
	
	def shell_is_explorer?
		current_shell = get_shell
		return nil if current_shell.nil?
		return true if current_shell.strip =~ /^explorer\.exe$/i 
		return false
	end
	
	def reset_shell(backup=false)
		was_mounted = true
		if @partition.mount_point.nil?
			was_mounted = false
			@partition.mount("rw")
		else 
			return false unless @partition.remount_rw
		end
		aux = shell_is_explorer?
		return nil if aux.nil?
		return true if aux == true
		# return false unless @partition.remount_rw
		mnt = @partition.mount_point
		if backup == true
			now = Time.new.to_i
			return false unless system("cp '#{@partition.mount_point[0]}/#{@regfile}' '#{@partition.mount_point[0]}/#{@regfile}.#{now.to_s}'") 
		end
		h = Hivex::open(mnt[0] + "/" + @regfile, { :write => 1})
		root = h.root()
		node = h.node_get_child(root, "Microsoft")
		if node.nil?
			$stderr.puts "no HKLM\\SOFTWARE\\Microsoft node: Probably not the correct hive"
			return false
		end
		node = h.node_get_child(node, "Windows NT")
		node = h.node_get_child(node, "CurrentVersion")
		node = h.node_get_child(node, "Winlogon")
		begin
			newshell = { :key => "Shell", :type => 1, :value => "explorer.exe" } #  .encode("UTF-16", "UTF-8") }
			h.node_set_value(node, newshell)
			h.commit(mnt[0] + "/" + @regfile)
			h.close
		rescue
			return false
		end
		h.close 
		return true
	end

end