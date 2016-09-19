module AwsSesSnsEngine
  module SesSenderEmail
    extend ActiveSupport::Concern

    included do
      before_create :ses_verification_email, if: -> { state == 'initial' && !skip_ses_verification_email }
      before_destroy :unregister_email
      scope :default_senders, -> { where(default_sender_email: true) }
      attr_accessor :skip_ses_verification_email

      def verified!
        subscribe_to_notifications
        update! state: 'verified'
      end

      def subscribe_to_notifications
        AwsSesSnsEngine::SnsNotificationService.subscribe_to_bounces_and_complaints email
      end

      def resend_verification!
        ses_verification_email!
      end

      def ses_verification_email
        AwsSesSnsEngine::SesManager.verify_new_sender email
        self.state = 'pending'
      end

      def ses_verification_email!
        ses_verification_email
        save!
      end

      def check_verification_status!
        if AwsSesSnsEngine::SesManager.verified_sender? email
          verified!
          true
        end
      end

      def unregister_email
        AwsSesSnsEngine::SesManager.delete_verified_sender email
      end

      def set_default_sender_email email, &block
        raise "can only set verified emails as default sender email" unless verified?
        transaction do
          yield
          update! default_sender_email: true
        end
      end

      # STATES

      def initial?
        state == 'initial'
      end

      def pending?
        state == 'pending'
      end

      def verified?
        state == 'verified'
      end
    end
  end
end
