
require 'spec_helper'

describe SenderEmail do

  let(:email) { 'johndoe@example.com' }
  subject { SenderEmail.new(email: email) }

  context "registering emails on SES" do

    it "add email to SES and set state PENDING" do
      sender_email = SenderEmail.new(email: email)
      expect(sender_email).to be_initial
      expect(AwsSesSnsEngine::SesManager).to receive(:verify_new_sender).with(email)
      sender_email.send_for_verification_request!
      expect(sender_email).to be_pending
    end

    it "verified email" do
      sender_email = SenderEmail.new(email: email, state: 'pending')
      expect(sender_email).to receive(:subscribe_to_notifications)
      sender_email.verified!
      expect(sender_email).to be_verified
    end

    it "unregisters email" do
      sender_email = SenderEmail.new(state: 'pending', email: email)
      expect(AwsSesSnsEngine::SesManager).to receive(:delete_verified_sender).with(email)
      sender_email.destroy!
    end
  end

  context "pending state" do
    it "checks if email is verified" do
      sender_email = SenderEmail.new(state: 'pending')
      expect(AwsSesSnsEngine::SesManager).to receive(:verified_sender?).with(sender_email.email).and_return(false)
      sender_email.check_verification_status!
      expect(sender_email).to be_pending

      expect(AwsSesSnsEngine::SesManager).to receive(:verified_sender?).with(sender_email.email).and_return(true)
      expect(sender_email).to receive(:verified!)
      sender_email.check_verification_status!
    end
  end

  context 'integrations' do
    it 'calls Aws Notification service to register for bounces' do
      expect(AwsSesSnsEngine::SnsNotificationService).to receive(:subscribe_to_bounces_and_complaints).with(subject.email)
      subject.subscribe_to_notifications
    end
    it "send or resend verification" do
      expect(AwsSesSnsEngine::SesManager).to receive(:verify_new_sender).with(subject.email).twice
      subject.resend_verification!
      subject.send_for_verification_request!
    end
  end
end
