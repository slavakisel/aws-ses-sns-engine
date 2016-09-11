module AwsSesSnsEngine
  class SesManager

    def self.configure opts
      @settings = opts.slice(:access_key_id, :secret_access_key)
      @aws_ses_sns_topic = opts[:ses_sns_topic]
      @sns_handler_class = opts[:sns_handler_class] || raise("sns_handler_class cannot be blank")
      @configured = true
    end

    def self.sns_topic
      @aws_ses_sns_topic
    end

    def self.sns_notification_handler
      klass = @sns_handler_class.constantize
      unless klass.respond_to? :inbound
        raise "AwsSesSnsEngine expected an sns handler klass to be defined and implementing method 'inbound'. Create class #{default_sns_notification_handler_name} or configure #{self.class} :sns_handler with custom class name"
      end
      klass
    end

    def self.default_sns_notification_handler_name
      'SnsNotificationHandler'
    end

    def self.ses
      @ses ||= ses_endpoint
    end

    def self.ses_endpoint
      if Rails.env.production?
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
