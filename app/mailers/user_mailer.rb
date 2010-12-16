class UserMailer < SublimeVideoMailer
  
  def account_suspended(user)
    @user = user
    mail(:to => "#{@user.full_name} <#{@user.email}>", :subject => "Your account has been suspended")
  end
  
  def account_unsuspended(user)
    @user = user
    mail(:to => "#{@user.full_name} <#{@user.email}>", :subject => "Your account has been un-suspended")
  end
  
  def account_archived(user)
    @user = user
    mail(:to => "#{@user.full_name} <#{@user.email}>", :subject => "Your account has been deleted")
  end
  
end