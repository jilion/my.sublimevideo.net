class DeviseMailer < Devise::Mailer

  default from: I18n.t("mailer.info.email_full")

end
