class UserMailer < ActionMailer::Base
  default :from => "no-response@sublimevideo.net"
  
  def account_suspended(user, reason)
    @user = user
    @reason = reason
    mail(:to => "#{user.full_name} <#{user.email}>", :subject => "Your account has been suspended")
  end
  
end