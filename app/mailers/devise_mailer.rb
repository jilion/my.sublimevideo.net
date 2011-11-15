class DeviseMailer < Devise::Mailer

  default from: I18n.t("mailer.default.from")

end
