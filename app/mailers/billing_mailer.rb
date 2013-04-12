class BillingMailer < Mailer
  default template_path: "mailers/#{self.mailer_name}", from: I18n.t('mailer.billing.email')

  helper :invoices, :sites
  include DisplayCase::ExhibitsHelper

  def trial_will_expire(billable_item_id)
    _setup_from_billable_item_id(billable_item_id)
    @no_reply = true

    key = case @days_until_end
          when 0
            'today'
          when 1
            'tomorrow'
          else
            'in_days'
          end

    mail(to: @user.email,
         subject: _subject(__method__, keys: [key], addon: "#{@item.title} #{@item.kind_for_email}", days: @days_until_end))
  end

  def trial_has_expired(site_id, item_class, item_id)
    _setup_from_site_id(site_id)
    @item = exhibit(item_class.constantize.find(item_id))

    mail(to: @user.email,
         subject: _subject(__method__, addon: "#{@item.title} #{@item.kind_for_email}"))
  end

  def credit_card_will_expire(user_id)
    @user = User.find(user_id)

    mail(to: _to_billing_email_fallback_to_email(@user),
         subject: _subject(__method__))
  end

  def transaction_succeeded(transaction_id)
    _setup_from_transaction_id(transaction_id)

    mail(to: _to_billing_email_fallback_to_email(@user),
         subject: _subject(__method__))
  end

  def transaction_failed(transaction_id)
    _setup_from_transaction_id(transaction_id)

    mail(to: _to_billing_email_fallback_to_email(@user),
         subject: _subject(__method__))
  end

  private

  def _to_billing_email_fallback_to_email(user)
    if user.billing_email?
      @billing_contact = true
      user.billing_email
    else
      user.email
    end
  end

  def _setup_from_site_id(site_id)
    @site = Site.find(site_id)
    @user = @site.user
  end

  def _setup_from_billable_item_id(billable_item_id)
    billable_item = BillableItem.find(billable_item_id)
    @item         = exhibit(billable_item.item)
    @site         = billable_item.site
    @user         = @site.user
    _setup_days_until_end
    _setup_trial_end_date
  end

  def _setup_from_transaction_id(transaction_id)
    @transaction = Transaction.find(transaction_id)
    @user        = @transaction.user
  end

  def _setup_days_until_end
    @days_until_end = TrialHandler.new(@site).trial_days_remaining(@item) || BusinessModel.days_for_trial
  end

  def _setup_trial_end_date
    @trial_end_date = TrialHandler.new(@site).trial_end_date(@item) || BusinessModel.days_for_trial.days.from_now
  end

end
