require "aws_ses_sns_engine/engine"
require "aws_ses_sns_engine/ses_manager"
require "aws_ses_sns_engine/sns_notification_error"
require "aws_ses_sns_engine/sns_notification_service"
require "aws_ses_sns_engine/sns_subscription_confirmation"
require 'hashie'
require 'aws/ses'
require_relative '../app/models/aws_ses_sns_engine/ses_sender_email.rb'
require_relative '..app/controllers/aws_ses_sns_engine/application_controller.rb'
require_relative '../app/controllers/aws_ses_sns_engine/sns_controller.rb'


module AwsSesSnsEngine
end
