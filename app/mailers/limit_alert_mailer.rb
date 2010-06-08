class LimitAlertMailer < ActionMailer::Base
  default :from => "no-response@sublimevideo.net"
  
  def limit_exceeded(user)
    @user = user
    mail(:to => "#{user.full_name} <#{user.email}>", :subject => "Limit exceeded")
  end
  
end