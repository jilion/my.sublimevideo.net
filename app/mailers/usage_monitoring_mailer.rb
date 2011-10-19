class UsageMonitoringMailer < DefaultMailer

  def plan_overused(site)
    @site = site
    mail(
      :to => "\"#{@site.user.full_name}\" <#{@site.user.email}>",
      :subject => "Peak Insurance activated for #{@site.hostname}"
    )
  end

  def plan_upgrade_required(site)
    @site = site
    mail(
      :to => "\"#{@site.user.full_name}\" <#{@site.user.email}>",
      :subject => "You need to upgrade your plan for #{@site.hostname}"
    )
  end

end
