module AwsSesSnsEngine
  class SnsController < ApplicationController

    def sns_endpoint
      SnsNotificationService.sns_message JSON.parse(request.raw_post)
      render nothing: true
    end
  end
end
