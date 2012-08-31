require_dependency 'business_model'

module SiteModules::Cycle
  extend ActiveSupport::Concern

  module ClassMethods

    def send_yearly_plan_will_be_renewed_email
      Site.in_plan_id(Plan.yearly_plans.map(&:id)).
      plan_will_be_renewed_on(5.days.from_now).
      find_each(batch_size: 100) do |site|
        BillingMailer.yearly_plan_will_be_renewed(site).deliver!
      end
    end

    def send_trial_will_expire_email
      BusinessModel.days_before_trial_end.each do |days_before_trial_end|
        Site.trial_expires_on(days_before_trial_end.days.from_now).
        find_each(batch_size: 100) do |site|
          BillingMailer.delay.trial_will_expire(site.id)
        end
      end
    end

    def downgrade_sites_leaving_trial
      Site.trial_ended.find_each(batch_size: 100) do |site|
        site.plan_id = Plan.free_plan.id
        site.skip_password(:save!)
        BillingMailer.delay.trial_has_expired(site.id)
      end
    end

    def renew_active_sites
      Site.renewable.each do |site|
        site.prepare_pending_attributes(false)
        site.skip_password(:save!)
      end
    end

  end

  %w[trial_started_at first_paid_plan_started_at pending_plan_started_at pending_plan_cycle_started_at].each do |attr|
    define_method :"#{attr}=" do |attribute|
      write_attribute(:"#{attr}", attribute.try(:midnight))
    end
  end

  def pending_plan_cycle_ended_at=(attribute)
    write_attribute(:pending_plan_cycle_ended_at, attribute.try(:end_of_day))
  end

  def trial_expires_on(timestamp)
    in_trial_plan? && plan_started_at == (timestamp - BusinessModel.days_for_trial.days).midnight
  end

  def trial_expires_in_less_than_or_equal_to(timestamp)
    in_trial_plan? && plan_started_at <= (timestamp - BusinessModel.days_for_trial.days).midnight
  end

  def trial_end
    in_trial_plan? ? (plan_started_at + BusinessModel.days_for_trial.days).yesterday.end_of_day : nil
  end

  # Tells if trial **actually** started and **now** ended
  def trial_ended?
    in_trial_plan? && plan_started_at < (BusinessModel.days_for_trial - 1).days.ago.midnight
  end

  def plan_cycle_ended?
    plan_cycle_ended_at? && plan_cycle_ended_at < Time.now.utc
  end

  def months_since(time)
    if time
      now = Time.now.utc
      months_since_time  = (now.year - time.year) * 12 + (now.month - time.month)
      months_since_time -= 1 if (time + months_since_time.months) > now

      months_since_time
    else
      0
    end
  end

  def days_since(time)
    time ? ((Time.now.utc.midnight.to_i - time.midnight.to_i) / 1.day) : 0
  end

  def advance_for_next_cycle_end(plan, start_time = plan_started_at)
    offset = months_since(start_time)
    offset = offset - (offset % 12) + 11 if plan.yearly?

    (offset + 1).months - 1.day
  end

  def plan_month_cycle_started_at
    case plan.cycle
    when 'month'
      plan_cycle_started_at
    when 'year'
      plan_cycle_started_at + months_since(plan_cycle_started_at).months
    when 'none'
      (1.month - 1.day).ago.midnight
    end
  end

  def plan_month_cycle_ended_at
    case plan.cycle
    when 'month'
      plan_cycle_ended_at
    when 'year'
      (plan_cycle_started_at + (months_since(plan_cycle_started_at) + 1).months - 1.day).end_of_day
    when 'none'
      Time.now.utc.end_of_day
    end
  end

  def plan_month_cycle_start_time
    plan_month_cycle_started_at.to_i
  end

  def plan_month_cycle_end_time
    plan_month_cycle_ended_at.to_i
  end

  # before_save if: :pending_plan_id_changed? / also called from SiteModules::Billing.renew_active_sites
  def prepare_pending_attributes(instant_charging = true)
    @instant_charging = instant_charging

    set_pending_plan_from_next_plan # Delayed downgrade

    set_pending_plan_started_at # New plan

    set_pending_plan_cycle_dates
  end

  def set_pending_plan_from_next_plan
    # Test with the pending_plan_cycle_ended_at first in the case where a failed invoice is present
    # so the current plan_cycle_ended_at is not up-to-date, but pending_plan_cycle_ended_at is!
    if next_cycle_plan_id? && ((pending_plan_cycle_ended_at || plan_cycle_ended_at) < Time.now.utc)
      self.pending_plan_id    = next_cycle_plan_id
      self.next_cycle_plan_id = nil
      @instant_charging       = false
    end
  end

  def set_pending_plan_started_at
    # Downgrade, creation or upgrade
    if pending_plan_id?
      if plan_cycle_ended? # Downgrade
        self.pending_plan_started_at = plan_cycle_ended_at.tomorrow
      else # Creation or upgrade
        self.pending_plan_started_at = plan_cycle_started_at || Time.now.utc
      end
    end
  end

  def set_pending_plan_cycle_dates
    if pending_plan_id? # New plan
      if pending_plan.unpaid_plan?
        self.pending_plan_cycle_started_at = nil
        self.pending_plan_cycle_ended_at   = nil
      else
        self.pending_plan_cycle_started_at = plan_id? && plan.yearly? ? pending_plan_started_at : pending_plan_started_at + months_since(pending_plan_started_at).months
        self.pending_plan_cycle_ended_at   = pending_plan_started_at +
                                             advance_for_next_cycle_end(pending_plan || plan, pending_plan_started_at)
      end
    elsif plan_cycle_ended? # renew
      offset = months_since(plan_started_at)
      offset = offset - (offset % 12) if plan.yearly?

      self.pending_plan_cycle_started_at = plan_started_at + offset.months
      self.pending_plan_cycle_ended_at   = plan_started_at + advance_for_next_cycle_end(plan, plan_started_at)
    end
  end

  # called from SiteModules::Billing#create_and_charge_invoice callback
  # and from Invoice#succeed's apply_site_pending_attributes callback
  def apply_pending_attributes
    # Remove upgrade required "state"
    reset_first_plan_upgrade_required_alert_sent_at

    write_attribute(:plan_id, pending_plan_id) if pending_plan_id?

    # force update
    self.plan_started_at       = pending_plan_started_at if pending_plan_started_at?
    self.plan_cycle_started_at = pending_plan_cycle_started_at
    self.plan_cycle_ended_at   = pending_plan_cycle_ended_at

    %w[plan_id plan_started_at plan_cycle_started_at plan_cycle_ended_at].each do |att|
      self.send("pending_#{att}=", nil)
    end

    %w[plan_started_at plan_cycle_started_at plan_cycle_ended_at].each do |att|
      self.send("#{att}_will_change!")
      self.send("pending_#{att}_will_change!")
    end
    self.pending_plan_id_will_change!

    self.skip_password(:save!)
  end

  def reset_first_plan_upgrade_required_alert_sent_at
    if plan_id? && pending_plan_id? && plan.upgrade?(pending_plan)
      self.first_plan_upgrade_required_alert_sent_at = nil
    end
  end

end
