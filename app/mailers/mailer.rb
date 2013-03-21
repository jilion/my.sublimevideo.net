class Mailer < ActionMailer::Base
  default from: I18n.t('mailer.info.email')

  helper :application
  add_template_helper(UrlsHelper)

  private

  def _subject(method_name, args = {})
    keys = [method_name] + args.fetch(:keys) { [] }
    I18n.t("mailer.#{self.mailer_name}.#{keys.join('.')}", args)
  end

end
