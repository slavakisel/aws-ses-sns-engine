module AwsSesSnsEngine
  class SnsController < ApplicationController

    def sns_endpoint
      SnsNotificationService.notification JSON.parse(request.raw_post)
      render nothing: true
    end
  end
end
