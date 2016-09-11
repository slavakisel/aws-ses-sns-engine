Rails.application.routes.draw do

  mount AwsSesSnsEngine::Engine => "/aws_ses_sns_engine"
end
