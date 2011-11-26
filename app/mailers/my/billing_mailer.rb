class My::BillingMailer < MyMailer
  default template_path: "mailers/#{self.mailer_name}", from: I18n.t('mailer.billing.email_full')

  helper :application, 'my/invoices', 'my/sites'
  include My::SitesHelper # the only way to include view helpers in here
                          # I don't feel dirty doing this since the email's subject IS a view so...

  def trial_will_end(site)
    @site = site
    @user = site.user
    hostname = @site.hostname.presence || 'your site'
    subject = full_days_until_trial_end(@site) > 1 ? I18n.t('mailer.billing_mailer.trial_will_end', hostname: hostname, days: full_days_until_trial_end(@site)) : I18n.t('mailer.billing_mailer.trial_will_end_tomorrow', hostname: hostname)

    mail(
      to: to(@user),
      subject: subject
    )
  end

  def credit_card_will_expire(user)
    @user = user

    mail(
      to: to(@user),
      subject: I18n.t('mailer.billing_mailer.credit_card_will_expire')
    )
  end

  def transaction_succeeded(transaction)
    @transaction = transaction
    @user = transaction.user

    mail(
      to: to(@user),
      subject: I18n.t('mailer.billing_mailer.transaction_succeeded')
    )
  end

  def transaction_failed(transaction)
    @transaction = transaction
    @user = transaction.user

    mail(
      to: to(@user),
      subject: I18n.t('mailer.billing_mailer.transaction_failed')
    )
  end

  def too_many_charging_attempts(invoice)
    @invoice = invoice
    @user = invoice.user

    mail(
      to: to(@user),
      subject: I18n.t('mailer.billing_mailer.too_many_charging_attempts', hostname: @invoice.site.hostname)
    )
  end

end
