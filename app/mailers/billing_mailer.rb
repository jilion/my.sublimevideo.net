class BillingMailer < Mailer
  default template_path: "mailers/#{self.mailer_name}", from: I18n.t('mailer.billing.email')

  helper :invoices, :sites
  include SitesHelper # the only way to include view helpers in here
                      # I don't feel dirty doing this since the email's subject IS a view so...

  def trial_will_expire(billable_item_id)
    extract_site_and_user_from_billable_item_id(billable_item_id)
    @design_or_addon_plan = @billable_item.item
    setup_kind
    setup_days_until_end
    setup_trial_end_date

    key = case @days_until_end
    when 0
      'today'
    when 1
      'tomorrow'
    else
      'in_days'
    end

    mail(
      to: to(@user),
      subject: I18n.t("mailer.billing_mailer.trial_will_expire.#{key}", addon: "#{@design_or_addon_plan.title} #{@kind}", days: @days_until_end)
    )
  end

  def trial_has_expired(site_id, design_or_addon_plan_class, design_or_addon_plan_id)
    extract_site_and_user_from_site_id(site_id)
    @design_or_addon_plan = design_or_addon_plan_class.constantize.find(design_or_addon_plan_id)
    setup_kind

    mail(
      to: to(@user),
      subject: I18n.t("mailer.billing_mailer.trial_has_expired", addon: "#{@design_or_addon_plan.title} #{@kind}")
    )
  end

  def credit_card_will_expire(user_id)
    @user = User.find(user_id)

    mail(
      to: to_billing(@user),
      subject: I18n.t('mailer.billing_mailer.credit_card_will_expire')
    )
  end

  def transaction_succeeded(transaction_id)
    extract_transaction_and_user_from_transaction_id(transaction_id)

    mail(
      to: to_billing(@user),
      subject: I18n.t('mailer.billing_mailer.transaction_succeeded')
    )
  end

  def transaction_failed(transaction_id)
    extract_transaction_and_user_from_transaction_id(transaction_id)

    mail(
      to: to_billing(@user),
      subject: I18n.t('mailer.billing_mailer.transaction_failed')
    )
  end

  private

  def to_billing(user)
    if user.billing_email?
      @billing_contact = true
      user.billing_name? ? "\"#{user.billing_name}\" <#{user.billing_email}>" : user.billing_email
    else
      to(user)
    end
  end

  def extract_transaction_and_user_from_transaction_id(transaction_id)
    @transaction = Transaction.find(transaction_id)
    @user        = @transaction.user
  end

  def extract_site_and_user_from_billable_item_id(billable_item_id)
    @billable_item = BillableItem.find(billable_item_id)
    @site          = @billable_item.site
    @user          = @site.user
  end

  def setup_kind
    @kind = @design_or_addon_plan.is_a?(App::Design) ? 'player design' : 'add-on'
  end

  def setup_days_until_end
    @days_until_end = TrialHandler.new(@site).trial_days_remaining(@design_or_addon_plan) || BusinessModel.days_for_trial
  end

  def setup_trial_end_date
    @trial_end_date = TrialHandler.new(@site).trial_end_date(@design_or_addon_plan) || BusinessModel.days_for_trial.days.from_now
  end

end
