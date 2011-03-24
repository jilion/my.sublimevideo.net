class UsageMonitoringMailer < SublimeVideoMailer

  def plan_player_hits_reached(site)
    @site = site
    mail(
      :to => "\"#{@site.user.full_name}\" <#{@site.user.email}>",
      :subject => "You have reached usage limit for your site #{@site.hostname}"
    )
  end
  
  def plan_upgrade_required(site)
    @site = site
    mail(
      :to => "\"#{@site.user.full_name}\" <#{@site.user.email}>",
      :subject => "You need to upgrade your plan for your site #{@site.hostname}"
    )
  end
  
end
