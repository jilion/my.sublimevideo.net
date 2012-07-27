class Mailer < ActionMailer::Base

  default from: I18n.t("mailer.info.email_full")

  helper :application
  add_template_helper(UrlsHelper)

  def to(user)
    user.name? ? "\"#{user.name}\" <#{user.email}>" : user.email
  end

  private

  def extract_site_and_user_from_site_id(site_id)
    @site = Site.find(site_id)
    @user = @site.user
  end

end
