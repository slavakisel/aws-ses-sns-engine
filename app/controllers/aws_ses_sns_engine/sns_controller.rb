module AwsSesSnsEngine
  class SnsController < ApplicationController
    def sns_endpoint
      SnsNotificationService.sns_message JSON.parse(request.raw_post)
      head :ok
    end
  end
end
