module AwsSesSnsEngine
  class SesManager

    def self.configure opts
      #puts "configuring", opts
      @settings = opts.slice(:access_key_id, :secret_access_key)
      @enable_for_development = opts[:enable_for_development]
      SnsNotificationService.configure opts.slice(:ses_sns_topic, :sns_handler_class)
      @configured = true
    end

    def self.ses
      @ses ||= ses_endpoint
    end

    def self.ses_endpoint
      if Rails.env.production? || ( @enable_for_development && Rails.env.test? )
        AWS::SES::Base.new(@settings)
      else
        Dummy.new
      end
    end

    def self.verify_new_sender email
      ses.addresses.verify(email)
    end
    def self.list_verified_senders
      ses.addresses.list.result
    end
    def self.verified_sender? email
      email.in?(list_verified_senders)
    end
    def self.delete_verified_sender email
      ses.addresses.delete email
    end

    #
    # The result is a list of data points, representing the last two weeks of sending activity. Each data point in the list contains statistics for a 15-minute interval. GetSendStatisticsResponse#data_points is an array where each element is a hash with give string keys:
    # Bounces
    # DeliveryAttempts
    # Rejects
    # Complaints
    # Timestamp
    def self.statistics
      response = ses.statistics
      response.data_points
    end

    class Dummy

      def method_missing(method, *args)
        case method
        when :result
          ["johndoe@example.com"]
        when :verify, :delete
          true
        when :addresses, :list
          self
        else
          super
        end
      end
    end
  end
end
