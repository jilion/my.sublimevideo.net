class UsageAlertMailer < SublimeVideoMailer

  def plan_player_hits_reached(site)
    @site = site
    mail(:to => "\"#{@site.user.full_name}\" <#{@site.user.email}>", :subject => "You have reached usage limit for your site #{@site.hostname}")
  end

  def next_plan_recommended(site)
    @site = site
    mail(:to => "\"#{@site.user.full_name}\" <#{@site.user.email}>", :subject => "You should upgrade your site #{@site.hostname} to the next plan")
  end

end