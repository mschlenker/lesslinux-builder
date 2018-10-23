
class MailNotifier

	def initialize(cfgfile)
		@xfile = REXML::Document.new(File.new(cfgfile))
		@sender = @xfile.elements["mailconfig/sender"].text.strip
		@sendernice = @xfile.elements["mailconfig/sendernice"].text.strip
		@receiver = @xfile.elements["mailconfig/receiver"].text.strip
		@mailhost = @xfile.elements["mailconfig/mailhost"].text.strip
		@mailport = @xfile.elements["mailconfig/mailhost"].attributes["port"].to_i
		@mailpass = @xfile.elements["mailconfig/mailpass"].text.strip
		@mailuser = @xfile.elements["mailconfig/mailuser"].text.strip
	end
	
	def send_mail(subject, body)
		marker = "Let5sep4rateS0meStuff"
		@mailtemplate =<<EOF
From: #{@sendernice} <#{@sender}>
To:
Subject: #{subject}
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=#{marker}

--#{marker}
Content-Type: text/plain; charset=UTF-8; format=flowed
Content-Transfer-Encoding:8bit

#{body}

--#{@marker}--
EOF

		mailer = Net::SMTP.start( @mailhost, @mailport,  'i.dont.want.to.tell.my.name', @mailuser, @mailpass)
		begin
			mailer.sendmail(body, @sender, [ @receiver ])
		rescue
		end

	end
end
