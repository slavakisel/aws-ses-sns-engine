class SenderEmail < ActiveRecord::Base
  include AwsSesSnsEngine::SesSenderEmail

  def set_as_default!
    set_default_sender_email email
  end
end
