class UserMailer < Mailer
  default template_path: "mailers/#{self.mailer_name}"

  def welcome(user_id)
    extract_user_from_user_id(user_id)

    mail(
      to: to(@user),
      subject: I18n.t('mailer.user_mailer.welcome')
    )
  end

  def account_suspended(user_id)
    extract_user_from_user_id(user_id)

    mail(
      to: to(@user),
      subject: I18n.t('mailer.user_mailer.account_suspended')
    )
  end

  def account_unsuspended(user_id)
    extract_user_from_user_id(user_id)

    mail(
      to: to(@user),
      subject: I18n.t('mailer.user_mailer.account_unsuspended')
    )
  end

  def account_archived(user_id)
    extract_user_from_user_id(user_id)

    mail(
      to: to(@user),
      subject: I18n.t('mailer.user_mailer.account_archived')
    )
  end

  private

  def extract_user_from_user_id(user_id)
    @user = User.find(user_id)
  end

end
