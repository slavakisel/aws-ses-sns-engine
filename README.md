# AwsSesSnsEngine

This project rocks and uses MIT-LICENSE.

WIP - this is not meant to be perfect and all-covering.

    Goal: Help register verified sender emails (`SesManager`) and subscribing to a topic and it's bounce and complaint messages (`SnsNotificationService`)

Manual setups

 1. AWS account
 2. Create an SNS Topic
 3. Create a subscription to the SNS Topic, using http `http://yourdomain.com/aws_ses_sns_engine/sns/sns_endpoint` (or set another if you remember to set a route alias)
 4. Implement the handler of bounce and complaint notifications (see below)

This enginge helps you register the SES emails to post messages on the Topics.


## Getting Started

Add to your Gemfile

    group :production do
      gem 'aws-ses-sns-engine', github: 'paladinsoftware/aws-ses-sns-engine', branch: :master, require: "aws_ses_sns_engine"
    end

### Initializer

for local testing, put the gem outside the production group and override initializer, here's an example assuming you did

    # file config/initializers/amazon_ses.rb

    if defined? AWS::SES::Base
      ActionMailer::Base.add_delivery_method :ses, AWS::SES::Base,
        :access_key_id     => ENV['SES_ACCESS_KEY_ID'],
        :secret_access_key => ENV['SES_SECRET_ACCESS_KEY']

      AwsSesSnsEngine::SesManager.configure(
        ActionMailer::Base.ses_settings.merge(
          ses_sns_topic: ENV['AWS_SES_SNS_TOPIC_SUBSCRIPTION'],
          sns_handler_class: 'Aws::SnsNotificationHandler',
          enable_for_development: true
        )
      )
    end

### Test Manually

    $ rails console
    $ AwsSesSnsEngine::SesManager.list_verified_senders

Check out the SesManager source code and SnsNotificationService for usages.


### Model

Simply include the SesSenderEmail module. This example assumes a model where ses sender email is associated to a company.

    class SenderEmail < ActiveRecord::Base
      include SesSenderEmail
      belongs_to :company

      def set_as_default!
        set_default_sender_email email do
          company.default_sender_email&.update!(default_sender_email: false)
          company.update! support_email: email
        end
      end
    end


### Migration

     create_table "sender_emails", force: :cascade do |t|
       t.string   "email",                                    null: false
       t.string   "state",                default: "initial", null: false
       t.datetime "created_at",                               null: false
       t.datetime "updated_at",                               null: false
       t.boolean  "default_sender_email", default: false,     null: false
     end

### Controller

example of controller. Ommitting auth and other things you'd normally need: 

    class SesSenderEmailsController < ApplicationController
        respond_to :json
        before_action :get_record, only: [:set_default_sender_email, :check_verification, :resend_verification, :destroy]
        attr_reader :sender_email

        def index
          sender_emails = SenderEmail.order(state: 'desc', default_sender_email: 'desc')
          respond_to do |format|
            format.html {}
            format.json { render json: sender_emails.to_json }
          end
        end

        def create
          sender_email = SenderEmail.create!(permitted_params)
          render json: sender_email.to_json
        end

        def resend_verification
          sender_email.resend_verification!
          render json: sender_email.to_json
        end

        def set_default_sender_email
          sender_email.set_as_default!
          render json: sender_email.to_json
        end

        def check_verification
          sender_email.check_verification_status!
          render json: sender_email.to_json
        end

        def destroy
          if sender_email.default_sender_email?
            raise "Cannot delete the default sender email. A new must be made default first"
          else
            sender_email.destroy!
          end
          render json: sender_email.to_json
        end

        private

        def get_record
          @sender_email = current_company.sender_emails.find(params[:id])
        end

        def permitted_params
          params.require(:sender_email).permit(:email)
        end
      end
    end

### Routes

routes.rb

    resources :ses_sender_emails do
      member do
        get :check_verification
        post :resend_verification
        post :set_default_sender_email
      end
    end


### TODO

 1. api documentation on what methods are available.
