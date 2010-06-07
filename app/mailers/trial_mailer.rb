class TrialMailer < ActionMailer::Base
  default :from => "no-response@sublimevideo.net"
  
  def usage_information(user)
    @user = user
    mail(:to => "#{user.full_name} <#{user.email}>", :subject => "Trial Usage as reach 50%")
  end
  
  def usage_warning(user)
    @user = user
    mail(:to => "#{user.full_name} <#{user.email}>", :subject => "Warning! Trial Usage as reach 90%")
  end
  
end