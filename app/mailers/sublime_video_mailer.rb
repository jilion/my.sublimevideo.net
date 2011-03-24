class SublimeVideoMailer < ActionMailer::Base
  helper :mailers
  
  default :from => "SublimeVideo <noreply@sublimevideo.net>"
end
