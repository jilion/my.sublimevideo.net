class BillingMailer < Mailer
  default template_path: "mailers/#{self.mailer_name}", from: I18n.t('mailer.billing.email_full')

  helper :invoices, :sites
  include SitesHelper # the only way to include view helpers in here
                      # I don't feel dirty doing this since the email's subject IS a view so...

  def trial_has_started(site)
    extract_site_and_user(site)

    mail(
      to: to(@user),
      subject: I18n.t("mailer.billing_mailer.trial_has_started", hostname: @site.hostname, days: @days_until_end)
    )
  end

  def trial_will_expire(site)
    extract_site_and_user(site)
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
    extract_site_and_user(site)
    @trial_plan = trial_plan

    mail(
      to: to(@user),
      subject: I18n.t("mailer.billing_mailer.trial_has_expired", hostname: @site.hostname)
    )
  end

  def yearly_plan_will_be_renewed(site)
    extract_site_and_user(site)
    @formatted_renewal_date = I18n.l(@site.plan_cycle_ended_at.tomorrow, format: :named_date)

    mail(
      to: to(@user),
      subject: I18n.t("mailer.billing_mailer.yearly_plan_will_be_renewed", hostname: @site.hostname, date: @formatted_renewal_date)
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
    @user        = transaction.user

    mail(
      to: to(@user),
      subject: I18n.t('mailer.billing_mailer.transaction_succeeded')
    )
  end

  def transaction_failed(transaction)
    @transaction = transaction
    @user        = transaction.user

    mail(
      to: to(@user),
      subject: I18n.t('mailer.billing_mailer.transaction_failed')
    )
  end

  def too_many_charging_attempts(invoice)
    @invoice = invoice
    @user    = invoice.user

    mail(
      to: to(@user),
      subject: I18n.t('mailer.billing_mailer.too_many_charging_attempts', hostname: @invoice.site.hostname)
    )
  end

private

  def extract_site_and_user(site)
    @site = site
    @user = site.user
  end

end
