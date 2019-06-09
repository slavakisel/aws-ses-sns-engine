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

```ruby
group :production do
  gem 'aws-ses', github: 'paladinsoftware/aws-ses', branch: 'master' # load dependency
  gem 'aws-ses-sns-engine', github: 'paladinsoftware/aws-ses-sns-engine', branch: :master, require: "aws_ses_sns_engine"
end
```

### Initializer

for local testing, put the gem outside the production group and override initializer, here's an example assuming you did implement SnsNotificationHandler.

```ruby
# file app/services/sns_notification_handler.rb
class SnsNotificationHandler
  def self.inbound message
    case message.notificationType
    when 'Bounce'
      emails = message.bounce.bouncedRecipients.map {|bounce| bounce.emailAddress}
      # do something with the emails
    when 'Complaint'
      emails = message.complaint.complainedRecipients.map {|complaint| complaint.emailAddress}
      # do something with the emails
    else
      # raise error or handle
      []
    end
    raise "Method not overridden"
  end

  def self.log_context notification_hash
    # do something with notification hash
  end
end

# file config/initializers/amazon_ses.rb

if defined? AWS::SES::Base
  ActionMailer::Base.add_delivery_method :ses, AWS::SES::Base,
    :access_key_id     => ENV['SES_ACCESS_KEY_ID'],
    :secret_access_key => ENV['SES_SECRET_ACCESS_KEY']

  AwsSesSnsEngine::SesManager.configure(
    ActionMailer::Base.ses_settings.merge(
      ses_sns_topic: ENV['AWS_SES_SNS_TOPIC_SUBSCRIPTION'],
      sns_handler_class: 'SnsNotificationHandler',
      enable_for_development: true
    )
  )
end
```

### Test Manually

```ruby
$ rails console

# if initializer not set up yet
$ AwsSesSnsEngine::SesManager.configure(
  access_key_id:     'YOUR_SES_ACCESS_KEY_ID',
  secret_access_key: 'YOUR_SES_SECRET_ACCESS_KEY',
  ses_sns_topic:     'YOUR_AWS_SES_SNS_TOPIC_SUBSCRIPTION', #optional
  sns_handler_class: 'YourSnsHandler', #optional
  enable_for_development: true #use false unless testing
)

# List all verified senders
$ AwsSesSnsEngine::SesManager.list_verified_senders

# Add email to list pending verification
$ AwsSesSnsEngine::SesManager.verify_new_sender email

# Check verification status
$ AwsSesSnsEngine::SesManager.verified_sender? email

# Delete
$ AwsSesSnsEngine::SesManager.delete_verified_sender email

```
Check out the SesManager source code and SnsNotificationService for usages.

#### SesSenderEmail module

You'll need to make a model that implements this. See Moddel section below for example.

Provides all the necessary methods to keep an updated list and to automatically subscribe to notification over SNS to SES bounces and complaint.

```ruby

$ ses_sender_email = MySesSenderEmailModel.find_by email: 'some@example.com'

# mark record as paid and subscribe it to SNS
$ ses_sender_email.verified!

# subscribe to notifications over SNS
$ ses_sender_email.subscribe_to_notifications

# explicitly send ses verification email
$ ses_sender_email.ses_verification_email

# explicitly send ses verification email and save!
# This is performed automatically when creating new SesSenderEmail records
$ ses_sender_email.ses_verification_email!

# resend SES verification email and save
$ ses_sender_email.resend_verification!

# Check the verification status in AWS SES
$ ses_sender_email.check_verification_status!

# Mark Ses Sender Email as default
$ ses_sender_email.set_default_sender_email do
    #your custom code related to the instance being marked as default
  end

# Model states, no AWS calls
$ ses_sender_email.initial? #uncommon state, means no ses verification email has been sent
$ ses_sender_email.pending?
$ ses_sender_email.verified?

```

### Model

Simply include the SesSenderEmail module. This example assumes a model where ses sender email is associated to a company.

```Ruby
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
```

### Migration

```ruby
 create_table "sender_emails", force: :cascade do |t|
   t.string   "email",                                    null: false
   t.string   "state",                default: "initial", null: false
   t.datetime "created_at",                               null: false
   t.datetime "updated_at",                               null: false
   t.boolean  "default_sender_email", default: false,     null: false
 end
```

### Controller

example of controller. Ommitting auth and other things you'd normally need:

```ruby
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
```

### Routes

routes.rb

```ruby
resources :ses_sender_emails do
  member do
    get :check_verification
    post :resend_verification
    post :set_default_sender_email
  end
end
```

### TODO

 1. api documentation on what methods are available.
