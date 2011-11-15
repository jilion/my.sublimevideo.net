class My::StatMailer < MyMailer
  default template_path: "mailers/#{self.mailer_name}"

  helper :application, 'my/invoices', 'my/sites'
  include My::SitesHelper # the only way to include view helpers in here
                          # I don't feel dirty doing this since the email's subject IS a view so...

  def stats_trial_will_end(site)
    @site = site
    @user = @site.user

    mail(
      to: to(@user),
      subject: I18n.t('mailer.stat_mailer.stats_trial_will_end', hostname: @site.hostname)
    )
  end

end
