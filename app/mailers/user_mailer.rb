class UserMailer < NoreplyMailer

  def account_suspended(user)
    @user = user
    mail(
      :to => "\"#{@user.full_name}\" <#{@user.email}>",
      :subject => "Your account has been suspended"
    )
  end

  def account_unsuspended(user)
    @user = user
    mail(
      :to => "\"#{@user.full_name}\" <#{@user.email}>",
      :subject => "Your account has been reactivated"
    )
  end

  def account_archived(user)
    @user = user
    mail(
      :to => "\"#{@user.full_name}\" <#{@user.email}>",
      :subject => "Your account has been deleted"
    )
  end

end
