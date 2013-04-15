class DeviseMailer < Devise::Mailer
  layout 'mailer'
  default from: I18n.t('mailer.info.email')
  helper :application
  add_template_helper(UrlsHelper)
end
