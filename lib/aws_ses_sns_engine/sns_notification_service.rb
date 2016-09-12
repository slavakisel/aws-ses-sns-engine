module AwsSesSnsEngine
  class SnsNotificationService

    def self.configure opts
      @sns_handler_class = opts[:sns_handler_class] || raise("sns_handler_class cannot be blank")
      @aws_ses_sns_topic = opts[:ses_sns_topic]
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

    def self.sns_topic
      @aws_ses_sns_topic
    end

    def self.ses
      @ses ||= ses_endpoint
    end

    def self.ses_endpoint
      if Rails.env.production?
        SesManager.ses
      elsif Rails.env.test?
        raise "always mock out the ses_endpoint in specs"
      else
        Dummy.new
      end
    end

    def self.arn
      sns_topic
    end

    def self.notification notification_hash
      sns_notification_handler.log_context notification_hash
      notification = Hashie::Mash.new notification_hash
      case notification.Type
      when "SubscriptionConfirmation"
        SnsSubscriptionConfirmation.confirm(notification.TopicArn, notification.Token)
      when "Notification"
        message = Hashie::Mash.new(JSON.parse(notification.Message))
        sns_notification_handler.inbound(message)
      else
        raise SnsNotificationError.new("Unknown notification type #{notification.Type}")
      end
    end

    def self.subscribe_to_bounces_and_complaints email
      ses.notifications.register email, 'Bounce', arn
      ses.notifications.register email, 'Complaint', arn
    end

    def self.list_notification_subscriptions email
      ses.notifications.get(email).result
    end

    def self.subscribed_to_bounces? email
      ses.notifications.get(email).result[:bounce_notification].present?
    end

    def self.subscribed_to_complaints? email
      ses.notifications.get(email).result[:complaint_notification].present?
    end

    def self.subscribed_to_deliveries? email
      ses.notifications.get(email).result[:delivery_notification].present?
    end

    class Dummy
      def method_missing(method, *args)
        if method == :result
          {
            bounce_notification: true,
            complaint_notification: true,
            delivery_notification: true
          }
        else
          self
        end
      end
    end
  end
end
