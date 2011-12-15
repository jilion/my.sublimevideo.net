class My::BillingMailer < MyMailer
  default template_path: "mailers/#{self.mailer_name}", from: I18n.t('mailer.billing.email_full')

  helper :application, 'my/invoices', 'my/sites'
  include My::SitesHelper # the only way to include view helpers in here
                          # I don't feel dirty doing this since the email's subject IS a view so...

    @site = site
    @user = site.user

    mail(
      to: to(@user),
  def trial_will_expire(site)
    @site = site
    @user = site.user
    @days_until_end = full_days_until_trial_end(@site)
    key = case @days_until_end
    when 1
      'today'
    when 2
      'tomorrow'
    else
      'in_days'
    end

    mail(
      to: to(@user),
      subject: I18n.t("mailer.billing_mailer.trial_will_expire.#{key}", hostname: @site.hostname, days: @days_until_end)
    )
  end

  def trial_has_expired(site, trial_plan)
    @site = site
    @trial_plan = trial_plan
    @user = site.user

    mail(
      to: to(@user),
      subject: I18n.t("mailer.billing_mailer.trial_has_expired", hostname: @site.hostname)
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
