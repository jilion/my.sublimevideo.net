class BillingMailer < Mailer
  default template_path: "mailers/#{self.mailer_name}", from: I18n.t('mailer.billing.email_full')

  helper :invoices, :sites
  include SitesHelper # the only way to include view helpers in here
                      # I don't feel dirty doing this since the email's subject IS a view so...

  def trial_will_expire(site_id)
    extract_site_and_user_from_site_id(site_id)

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
      subject: I18n.t("mailer.billing_mailer.trial_will_expire.#{key}", hostname: @site.hostname_or_token, days: @days_until_end)
    )
  end

  def credit_card_will_expire(user_id)
    @user = User.find(user_id)

    mail(
      to: to(@user),
      subject: I18n.t('mailer.billing_mailer.credit_card_will_expire')
    )
  end

  def transaction_succeeded(transaction_id)
    extract_transaction_and_user_from_transaction_id(transaction_id)

    mail(
      to: to(@user),
      subject: I18n.t('mailer.billing_mailer.transaction_succeeded')
    )
  end

  def transaction_failed(transaction_id)
    extract_transaction_and_user_from_transaction_id(transaction_id)

    mail(
      to: to(@user),
      subject: I18n.t('mailer.billing_mailer.transaction_failed')
    )
  end

  private

  def extract_transaction_and_user_from_transaction_id(transaction_id)
    @transaction = Transaction.find(transaction_id)
    @user        = @transaction.user
  end

end
