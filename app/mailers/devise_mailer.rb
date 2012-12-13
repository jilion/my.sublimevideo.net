class DeviseMailer < Devise::Mailer

  default from: I18n.t("mailer.info.email")

  helper :application
  add_template_helper(UrlsHelper)

  layout 'mailer'

end
