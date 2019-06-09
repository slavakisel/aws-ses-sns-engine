module AwsSesSnsEngine
  class SnsSubscriptionConfirmation
    def self.confirm(arn, token)
      sns = Fog::AWS::SNS.new(
      	aws_access_key_id: SesManager.settings[:access_key_id],
      	aws_secret_access_key: SesManager.settings[:secret_access_key]
      )
      sns.confirm_subscription(arn, token)
    end
  end
end
