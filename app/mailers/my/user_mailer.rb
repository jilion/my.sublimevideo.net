class My::UserMailer < MyMailer
  default template_path: "mailers/#{self.mailer_name}"

  def account_suspended(user)
    @user = user

    mail(
      to: to(@user),
      subject: I18n.t('mailer.user_mailer.account_suspended')
    )
  end

  def account_unsuspended(user)
    @user = user

    mail(
      to: to(@user),
      subject: I18n.t('mailer.user_mailer.account_unsuspended')
    )
  end

  def account_archived(user)
    @user = user

    mail(
      to: to(@user),
      subject: I18n.t('mailer.user_mailer.account_archived')
    )
  end

end
