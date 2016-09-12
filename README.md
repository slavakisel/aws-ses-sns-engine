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

Initializer

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

Test Manually

    $ rails console
    $ AwsSesSnsEngine::SesManager.list_verified_senders

Check out the SesManager source code and SnsNotificationService for usages.

### TODO

 1. controller and model module for verified sender emails and automatic subscription upon verified email
 2. api documentation on what methods are available.
