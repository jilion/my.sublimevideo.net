class ApplicationMailer < ActionMailer::Base
  default from: I18n.t("mailer.info.email_full")

  def to(user)
    user.name? ? "\"#{user.name}\" <#{user.email}>" : user.email
  end

end
