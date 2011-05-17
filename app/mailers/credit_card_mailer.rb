class CreditCardMailer < SublimeVideoMailer
  default :from => "SublimeVideo <billing@sublimevideo.net>"

  def will_expire(user)
    @user = user
    mail(
      :to => "\"#{@user.full_name}\" <#{@user.email}>",
      :subject => "Your credit card will expire at the end of the month"
    )
  end

end
