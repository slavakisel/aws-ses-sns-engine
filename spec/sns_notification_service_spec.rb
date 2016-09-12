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

end
