class UsageAlertMailer < SublimeVideoMailer
  
  def limit_reached(site)
    @site = site
    mail(:to => "\"#{@site.user.full_name}\" <#{@site.user.email}>", :subject => "You have reached usage limit for your site #{@site.hostname}")
  end
  
end