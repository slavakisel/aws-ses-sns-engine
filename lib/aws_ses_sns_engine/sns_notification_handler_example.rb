module AwsSesSnsEngine
  class SnsNotificationHandlerExample
    def self.inbound message
      if message.notificationType == 'Bounce'
        emails = message.bounce.bouncedRecipients.map {|bounce| bounce.emailAddress}
        #do something with the emails
      elsif message.notificationType == 'Complaint'
        emails = message.complaint.complainedRecipients.map {|complaint| complaint.emailAddress}
        #do something with the emails
      else
        #raise error or handle
        []
      end
      raise "Method not overridden"
      

    end

    def self.log_context notification_hash
      Honeybadger.context notification_hash
    end
  end
end
