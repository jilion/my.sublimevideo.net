class ApplicationMailer < ActionMailer::Base
  default from: I18n.t("mailer.default.from")

  def to(user)
    "\"#{user.name}\" <#{user.email}>"
  end

end
