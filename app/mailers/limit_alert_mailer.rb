class LimitAlertMailer < SublimeVideoMailer
  
  def limit_exceeded(user)
    @user = user
    mail(:to => "#{user.full_name} <#{user.email}>", :subject => "Limit exceeded")
  end
  
end