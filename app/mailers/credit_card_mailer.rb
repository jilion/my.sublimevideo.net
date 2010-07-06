class CreditCardMailer < SublimeVideoMailer
  
  def is_expired(user)
    @user = user
    mail(:to => "#{user.full_name} <#{user.email}>", :subject => "Your credit card is expired")
  end
  
  def will_expire(user)
    @user = user
    mail(:to => "#{user.full_name} <#{user.email}>", :subject => "Your credit card will expire at the end of the month")
  end
  
end