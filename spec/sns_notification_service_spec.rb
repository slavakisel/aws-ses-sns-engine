require 'spec_helper'

describe AwsSesSnsEngine::SnsNotificationService do
  it "can subscribe to bounce and complaint notifications for an email" do
    email = 'johndoe@example.com'
    notifications_double = double
    expect(described_class).to receive(:ses).twice.and_return(double(notifications: notifications_double))
    expect(notifications_double).to receive(:register).with(email, 'Bounce', described_class.arn)
    expect(notifications_double).to receive(:register).with(email, 'Complaint', described_class.arn)
    described_class.subscribe_to_bounces_and_complaints email
  end

  context "method sns_subscription_succeeded" do
    let(:subscription_success) do
      {
        "Type" => "Notification",
        "Message" => "{\"notificationType\":\"AmazonSnsSubscriptionSucceeded\",\"message\":\"some message\"}\n"
      }
    end

    context "is defined" do
      let(:sns_notification_handler) { SnsSubsriptionSuccessSnsNotificationHandler }
      it "is implemented" do
        allow(described_class).to receive(:sns_notification_handler).and_return(sns_notification_handler)
        expect(sns_notification_handler).to receive(:sns_subscription_succeeded).and_call_original
        expect(described_class.sns_message(subscription_success)
).to be_truthy
      end
    end

    context "is not defined" do
      let(:sns_notification_handler) { SnsNotificationHandlerWithoutSnsSubsriptionSuccess }
      it "does nothing" do
        allow(described_class).to receive(:sns_notification_handler).and_return(sns_notification_handler)
        expect(sns_notification_handler).not_to respond_to(:sns_subscription_succeeded)
        expect(described_class.sns_message(subscription_success)).to be_nil
      end
    end
  end

  class SnsNotificationHandlerWithoutSnsSubsriptionSuccess
    def self.inbound message
    end
    def self.log_context notification_hash
    end
  end
  class SnsSubsriptionSuccessSnsNotificationHandler
    def self.inbound message
    end
    def self.log_context notification_hash
    end
    def self.sns_subscription_succeeded message
      true
    end
  end
end
