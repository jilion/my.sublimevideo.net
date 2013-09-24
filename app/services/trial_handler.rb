class TrialHandler
  attr_reader :site

  def initialize(site)
    @site = site
  end

  # =====================
  # = Scheduled methods =
  # =====================
  def self.send_trial_will_expire_emails
    _sites_with_subscriptions_in_trial.find_each do |site|
      delay(queue: 'my')._send_trial_will_expire_emails(site.id)
    end
  end

  def self.activate_billable_items_out_of_trial
    _sites_with_subscriptions_in_trial.find_each do |site|
      delay(queue: 'my')._activate_billable_items_out_of_trial(site.id)
    end
  end

  # ===========================
  # = Public instance methods =
  # ===========================
  def send_trial_will_expire_emails
    BusinessModel.days_before_trial_end.each do |days_before_trial_end|
      _subscriptions_exiting_trial_on(days_before_trial_end.days.from_now).each do |subscription|
        BillingMailer.delay(queue: 'my-mailer').trial_will_expire(subscription.id)
      end
    end
  end

  def activate_billable_items_out_of_trial
    return if _no_subscriptions_out_of_trial?

    new_subscriptions, emails = _new_subscriptions_and_emails

    SiteManager.new(site).update_billable_items(new_subscriptions[:designs], new_subscriptions[:addon_plans])

    emails.each do |email|
      BillingMailer.delay(queue: 'my-mailer').trial_has_expired(site.id, email[:item_class], email[:item_id])
    end
  end

  def trial_ends_on?(design_or_addon_plan, date)
    if subscription = site.billable_item_activities.with_item(design_or_addon_plan).state('trial').first
      date.midnight == trial_end_date(subscription.item).midnight + 1.day
    else
      false
    end
  end

  def out_of_trial?(design_or_addon_plan)
    return true if site.billable_item_activities.with_item(design_or_addon_plan).state('subscribed').exists?

    if subscription = site.billable_item_activities.with_item(design_or_addon_plan).state(%w[beta trial]).first
      trial_end_date(subscription.item) <= Time.now.utc
    else
      false
    end
  end

  def trial_end_date(design_or_addon_plan)
    if subscription = site.billable_item_activities.with_item(design_or_addon_plan).state(%w[beta trial]).first
      subscription.created_at + BusinessModel.days_for_trial.days
    else
      nil
    end
  end

  def trial_days_remaining(design_or_addon_plan)
    return nil if design_or_addon_plan.beta? || design_or_addon_plan.free?
    return 0 if out_of_trial?(design_or_addon_plan)

    if trial_end_date = trial_end_date(design_or_addon_plan)
      [0, ((trial_end_date - Time.now.utc + 1.day) / 1.day).to_i].max
    end
  end

  private

  # Delayed method
  def self._send_trial_will_expire_emails(site_id)
    new(_find_site(site_id)).send_trial_will_expire_emails
  end

  # Delayed method
  def self._activate_billable_items_out_of_trial(site_id)
    new(_find_site(site_id)).activate_billable_items_out_of_trial
  end

  def self._sites_with_subscriptions_in_trial
    Site.not_archived.select('DISTINCT("sites".*)').joins(:billable_items).where(billable_items: { state:'trial' })
  end

  def self._find_site(site_id)
    Site.not_archived.find(site_id)
  end

  def _no_subscriptions_out_of_trial?
    site.billable_items.state('trial').none? { |subscription| out_of_trial?(subscription.item) }
  end

  def _new_subscriptions_and_emails
    subscriptions, emails = { designs: {}, addon_plans: {} }, []

    site.billable_items.state('trial').each do |subscription|
      next unless out_of_trial?(subscription.item)

      key = subscription.item_type.demodulize.tableize.to_sym
      subscriptions[key][subscription.item_parent_name] = if site.user.cc?
        subscription.item.id
      else
        emails << { item_class: subscription.item_type, item_id: subscription.item.id }
        if free_plan = subscription.item.free_plan
          free_plan.id
        else
          '0'
        end
      end
    end

    [subscriptions, emails]
  end

  def _subscriptions_exiting_trial_on(date)
    site.billable_items.select { |subscription| trial_ends_on?(subscription.item, date) }
  end

end
