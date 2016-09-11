AwsSesSnsEngine::SesManager.configure(
  access_key_id:     ENV['SES_ACCESS_KEY_ID'],
  secret_access_key: ENV['SES_SECRET_ACCESS_KEY'],
  ses_sns_topic:     ENV['AWS_SES_SNS_TOPIC_SUBSCRIPTION'],
  sns_handler_class: AwsSesSnsEngine::SesManager.default_sns_notification_handler_name
)
