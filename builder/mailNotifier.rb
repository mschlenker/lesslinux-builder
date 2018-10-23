
class MailNotifier

	def initialize(cfgfile)
		@xfile = REXML::Document.new(File.new(cfgfile))
		@sender = @xfile.elements["mailconfig/sender"].text.strip
		@sendernice = @xfile.elements["mailconfig/sendernice"].text.strip
		@receiver = @xfile.elements["mailconfig/receiver"].text.strip
		@mailhost = @xfile.elements["mailconfig/mailhost"].text.strip
		@mailhost = @xfile.elements["mailport/mailhost"].attributes["port"].to_i
		@mailpass = @xfile.elements["mailconfig/mailpass"].text.strip
	end
	
	def send_mail(subject, body)
		
	end
end
