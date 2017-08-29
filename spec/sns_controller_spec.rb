require 'spec_helper'

describe AwsSesSnsEngine::SnsController, type: :controller do
  routes { AwsSesSnsEngine::Engine.routes }

  describe "confirmation" do
    let(:confirmation_raw_json) do
      '{
            "Type" : "SubscriptionConfirmation",
            "MessageId" : "33444d09-1ca3-442f-a736-c1848ccbfcd9",
            "TopicArn" : "arn:aws:sns:us-east-1:123456789012:MyTopic",
            "Token" : "2336412f37fb687f5d51e6e241d164b14f9e81c6c9aa29262ce3fb4117fb80948fc247162d9d2b1b74c51218008d9b17aa760450f775d3dc0a5bede65011342fd6b520e5404d4e01cc29f5ba5dcc07e91498edde82b7401f7a62cc272416eed80929ae7d3c5395ceb6730fa5a41d0029d0bae9128822d25c7b6ab5b5739c9f61",
            "SubscribeURL" : "https://sns.us-east-1.amazonaws.com/?Action=ConfirmSubscription&TopicArn=arn:aws:sns:us-east-1:123456789012:MyTopic&Token=2336412f37fb687f5d51e6e241d09c805a5a57b30d712f794cc5f6a988666d92768dd60a747ba6f3beb71854e285d6ad02428b09ceece29417f1f02d609c582afbacc99c583a916b9981dd2728f4ae6fdb82efd087cc3b7849e05798d2d2785c03b0879594eeac82c01f235d0e717736"}'
    end

    it "dispatches subscription confirmation" do
      h = JSON.parse(confirmation_raw_json)
      expect(AwsSesSnsEngine::SnsSubscriptionConfirmation).to receive(:confirm).with(h['TopicArn'], h['Token'])
      @request.env['RAW_POST_DATA'] = confirmation_raw_json
      post :sns_endpoint, {}
    end
  end

  describe "notification" do
    let(:notification_raw_json) do
      '{"Type" : "Notification",
        "Message" :  "{ \"uuid\": \"12341234uu\",  \"status\": \"Processing\" }" }'
    end

    it "dispatches notification" do
      @request.env['RAW_POST_DATA'] = notification_raw_json
      expect(SnsNotificationHandler).to receive(:inbound).with({"uuid"=>"12341234uu", "status"=>"Processing"})
      post :sns_endpoint, {}
    end
  end

  describe "Aws SNS Subscription Succeeded" do
    let(:subscription_successful_raw_json) do

      '{
        "Type" : "Notification",
        "MessageId" : "123456789-1-2-3-4-8ad2032d88b",
        "TopicArn" : "arn:aws:sns:us-east-1:123456789012:MyTopic",
        "Message" : "{\"notificationType\":\"AmazonSnsSubscriptionSucceeded\",\"message\":\"You have successfully subscribed your Amazon SNS topic \'arn:aws:sns:us-east-1:123456789:paladin_email_bounces\' to receive \'Complaint\' notifications from Amazon SES for identity \'info@example.com\'.\"}\n"
      }'
    end

    module SnsSubscriptionSuccess
      def sns_subscription_succeeded(*args); end
    end
    it "successful AWS SNS Subscription" do
      @request.env['RAW_POST_DATA'] = subscription_successful_raw_json
      SnsNotificationHandler.extend(SnsSubscriptionSuccess)
      expect(SnsNotificationHandler).not_to receive(:inbound)
      expect(SnsNotificationHandler).to receive(:sns_subscription_succeeded)

      post :sns_endpoint, {}
    end
  end
end
