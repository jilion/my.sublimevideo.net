class DeviseMailer < Devise::Mailer
  default from: 'info@sublimevideo.net'

  helper :application
  add_template_helper(UrlsHelper)

  layout 'mailer'
end
