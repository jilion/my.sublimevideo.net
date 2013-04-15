class DeviseMailer < Devise::Mailer
  default from: 'SublimeVideo <info@sublimevideo.net>'

  helper :application
  add_template_helper(UrlsHelper)

  layout 'mailer'
end
