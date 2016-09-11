module AwsSesSnsEngine
  class SnsSubscriptionConfirmation
    def self.confirm(arn, token)
      sns = Fog::AWS::SNS.new(SnsNotificationService.settings)
      sns.confirm_subscription(arn, token)
    end
  end
end
