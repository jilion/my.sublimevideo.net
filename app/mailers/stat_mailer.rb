class StatMailer < DefaultMailer
  helper :application, :invoices, :sites
  include SitesHelper # the only way to include view helpers in here
                      # I don't feel dirty doing this since the email's subject IS a view so...

  def stats_trial_will_end(site)
    @site = site
    mail(
      :to => "\"#{@site.user.full_name}\" <#{@site.user.email}>",
      :subject => "Your stats trial for #{@site.hostname} will expire in 2 days"
    )
  end

end
