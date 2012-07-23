class UsageMonitoringMailer < Mailer
  default template_path: "mailers/#{self.mailer_name}"

  helper :sites

  def plan_overused(site_id)
    extract_site_and_user_from_site_id(site_id)

    mail(
      to: to(@user),
      subject: I18n.t('mailer.usage_monitoring_mailer.plan_overused', hostname: @site.hostname)
    )
  end

  def plan_upgrade_required(site_id)
    extract_site_and_user_from_site_id(site_id)

    mail(
      to: to(@user),
      subject: I18n.t('mailer.usage_monitoring_mailer.plan_upgrade_required', hostname: @site.hostname)
    )
  end

end
