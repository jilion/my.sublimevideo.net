class UsageMonitoringMailer < Mailer
  default template_path: "mailers/#{self.mailer_name}"

  def plan_overused(site)
    @site = site
    @user = @site.user

    mail(
      to: to(@user),
      subject: I18n.t('mailer.usage_monitoring_mailer.plan_overused', hostname: @site.hostname)
    )
  end

  def plan_upgrade_required(site)
    @site = site
    @user = @site.user

    mail(
      to: to(@user),
      subject: I18n.t('mailer.usage_monitoring_mailer.plan_upgrade_required', hostname: @site.hostname)
    )
  end

end
