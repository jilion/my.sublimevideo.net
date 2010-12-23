class TrialMailer < SublimeVideoMailer
  
  def usage_information(user)
    @user = user
    mail(:to => "\"#{user.full_name}\" <#{user.email}>", :subject => "Trial usage has reached 50%")
  end
  
  def usage_warning(user)
    @user = user
    mail(:to => "\"#{user.full_name}\" <#{user.email}>", :subject => "Warning! Trial usage has reached 90%")
  end
  
end