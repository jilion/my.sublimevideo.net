class BillingMailer < ActionMailer::Base
  default from: "SublimeVideo Billing <billing@sublimevideo.net>"
  helper :application, 'my/invoices', 'my/sites'
  include My::SitesHelper # the only way to include view helpers in here
                          # I don't feel dirty doing this since the email's subject IS a view so...

  def trial_will_end(site)
    @site = site
    mail(
      to: "\"#{@site.user.name}\" <#{@site.user.email}>",
      subject: "Trial for #{@site.hostname.presence || 'your site'} will expire in #{full_days_until_trial_end(@site)} days"
    )
  end

  def credit_card_will_expire(user)
    @user = user
    mail(
      to: "\"#{@user.name}\" <#{@user.email}>",
      subject: "Your credit card will expire at the end of the month"
    )
  end

  def transaction_succeeded(transaction)
    @transaction = transaction
    mail(
      to: "\"#{@transaction.user.name}\" <#{@transaction.user.email}>",
      subject: "Payment approved"
    )
  end

  def transaction_failed(transaction)
    @transaction = transaction
    mail(
      to: "\"#{@transaction.user.name}\" <#{@transaction.user.email}>",
      subject: "Problem processing your payment"
    )
  end

  def too_many_charging_attempts(invoice)
    @invoice = invoice
    mail(
      to: "\"#{@invoice.user.name}\" <#{@invoice.user.email}>",
      subject: "Payment for #{@invoice.site.hostname} has failed multiple times"
    )
  end

end
