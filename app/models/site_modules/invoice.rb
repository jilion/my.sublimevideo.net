require_dependency 'business_model'

module SiteModules::Invoice
  extend ActiveSupport::Concern

  module ClassMethods
    def send_yearly_plan_will_be_renewed
      Site.not_in_trial.in_plan_id(Plan.yearly_plans.map(&:id)).
      plan_will_be_renewed_on(5.days.from_now).
      find_each(batch_size: 100) do |site|
        BillingMailer.yearly_plan_will_be_renewed(site).deliver!
      end
    end

    def send_trial_will_expire
      BusinessModel.days_before_trial_end.each do |days_before_trial_end|
        Site.in_trial.paid_plan.where(first_paid_plan_started_at: nil).
        trial_expires_on(days_before_trial_end.days.from_now).
        find_each(batch_size: 100) do |site|
          BillingMailer.trial_will_expire(site).deliver! unless site.user.credit_card?
        end
      end
    end

    def activate_or_downgrade_sites_leaving_trial
      Site.not_in_trial.paid_plan.where(first_paid_plan_started_at: nil).find_each(batch_size: 100) do |site|
        if site.user.credit_card?
          site.prepare_activation
          site.prepare_pending_attributes
        else
          trial_plan   = site.plan
          site.plan_id = Plan.free_plan.id
          BillingMailer.trial_has_expired(site, trial_plan).deliver!
        end
        site.save_skip_pwd
      end
    end

    def renew_active_sites
      Site.renewable.each do |site|
        site.prepare_pending_attributes
        site.save_skip_pwd
      end
    end
  end

  %w[trial_started_at first_paid_plan_started_at pending_plan_started_at pending_plan_cycle_started_at].each do |attr|
    define_method :"#{attr}=" do |attribute|
      write_attribute(:"#{attr}", attribute.try(:midnight))
    end
  end

  def pending_plan_cycle_ended_at=(attribute)
    write_attribute(:pending_plan_cycle_ended_at, attribute.try(:to_datetime).try(:end_of_day))
  end

  %w[open failed waiting].each do |invoice_state|
    define_method :"invoices_#{invoice_state}?" do
      invoices.any? { |i| i.send("#{invoice_state}?") }
    end
  end

  %w[free sponsored paid custom].each do |plan_name|
    define_method :"in_#{plan_name}_plan?" do
      plan && plan.send("#{plan_name}_plan?")
    end
  end

  def prepare_activation
    self.first_paid_plan_started_at = Time.now.utc unless first_paid_plan_started_at?
  end

  def prepare_trial_skipping
    self.trial_started_at = (BusinessModel.days_for_trial + 1).days.ago
    prepare_activation
  end

  def skip_trial?
    @skip_trial.to_i.nonzero?
  end

  def instant_charging?
    @instant_charging
  end

  def will_be_in_free_plan?
    if id = (pending_plan_id || next_cycle_plan_id)
      Plan.find(id).free_plan?
    end
  end

  def will_be_in_paid_plan?
    pending_plan_id? && pending_plan.paid_plan?
  end

  def in_or_will_be_in_paid_plan?
    in_paid_plan? || will_be_in_paid_plan?
  end

  # Tells if trial **actually** started and is **not yet** ended
  def in_trial?
    trial_started_at? && trial_started_at >= (BusinessModel.days_for_trial - 1).days.ago.midnight
  end

  # Tells if trial **actually** started and **now** ended
  def trial_ended?
    trial_started_at? && trial_started_at < (BusinessModel.days_for_trial - 1).days.ago.midnight
  end

  # Tells if trial has **never been** started or is **not yet** ended
  def trial_not_started_or_in_trial?
    !trial_ended?
  end

  def trial_expires_on(timestamp)
    trial_started_at? && trial_started_at.midnight == (timestamp - BusinessModel.days_for_trial.days).midnight
  end

  def trial_expires_in_less_than_or_equal_to(timestamp)
    trial_started_at? && !trial_ended? && trial_started_at.midnight <= (timestamp - BusinessModel.days_for_trial.days).midnight
  end

  def trial_end
    trial_started_at? ? (trial_started_at + BusinessModel.days_for_trial.days).yesterday.end_of_day : nil
  end

  def refunded?
    archived? && refunded_at?
  end

  def plan_cycle_ended?
    plan_cycle_ended_at? && plan_cycle_ended_at < Time.now.utc
  end

  def last_paid_invoice
    invoices.paid.order(:paid_at).try(:last)
  end

  def last_paid_plan
    last_paid_invoice ? last_paid_invoice.plan_invoice_items.find { |pii| pii.amount > 0 }.try(:item) : nil
  end

  def last_paid_plan_price
    last_paid_plan ? last_paid_invoice.plan_invoice_items.find { |pii| pii.amount > 0 }.try(:price) : 0
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
    cycle = trial_ended? && plan_cycle_started_at? ? plan.read_attribute(:cycle) : 'none' # strange error in specs when using .cycle

    case cycle
    when 'month'
      plan_cycle_started_at
    when 'year'
      plan_cycle_started_at + months_since(plan_cycle_started_at).months
    when 'none'
      (1.month - 1.day).ago.midnight
    end
  end

  def plan_month_cycle_ended_at
    cycle = trial_ended? && plan_cycle_ended_at? ? plan.read_attribute(:cycle) : 'none' # strange error in specs when using .cycle

    case cycle
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

  # before_save :if => :pending_plan_id_changed? / also called from SiteModules::Invoice.renew_active_sites
  def prepare_pending_attributes
    @instant_charging = false

    # Downgrade
    # Test with the pending_plan_cycle_ended_at first in the case where a failed invoice is present
    # so the current plan_cycle_ended_at is not up-to-date, but pending_plan_cycle_ended_at is!
    if next_cycle_plan_id? && ((pending_plan_cycle_ended_at || plan_cycle_ended_at) < Time.now.utc)
      self.pending_plan_id    = next_cycle_plan_id
      self.next_cycle_plan_id = nil
    end

    # new paid plan (creation, activation, upgrade or downgrade)
    if (pending_plan_id_changed? && pending_plan_id?) ||
       first_paid_plan_started_at_changed? || # Activation
       skip_trial?

      # Downgrade
      if plan_cycle_ended?
        self.pending_plan_started_at = plan_cycle_ended_at.tomorrow

      # Creation, activation or upgrade
      else
        prepare_trial_skipping if skip_trial?

        # Upgrade or creation with "skip trial"
        @instant_charging = trial_ended? && (!first_paid_plan_started_at_changed? || skip_trial?)

        self.pending_plan_started_at = plan_cycle_started_at || Time.now.utc
      end

      if trial_ended? &&
        (
          # Activation or creation with "skip trial"
          first_paid_plan_started_at_changed? ||
          # Upgrade, downgrade or creation with "skip trial"
          (pending_plan_id? && pending_plan.paid_plan?)
        )
        self.pending_plan_cycle_started_at = plan_id? && plan.yearly? ? pending_plan_started_at : pending_plan_started_at + months_since(pending_plan_started_at).months
        self.pending_plan_cycle_ended_at   = pending_plan_started_at +
                                             advance_for_next_cycle_end(pending_plan || plan, pending_plan_started_at)
      else
        self.pending_plan_cycle_started_at = nil
        self.pending_plan_cycle_ended_at   = nil
      end

    # normal renew
    elsif plan_cycle_ended?
      offset = months_since(plan_started_at)
      offset = offset - (offset % 12) if plan.yearly?

      self.pending_plan_cycle_started_at = plan_started_at + offset.months
      self.pending_plan_cycle_ended_at   = plan_started_at + advance_for_next_cycle_end(plan, plan_started_at)
    end

    true # don't block the callbacks chain
  end

  # called from SiteModules::Invoice#create_and_charge_invoice callback
  # and from Invoice#succeed's apply_site_pending_attributes callback
  def apply_pending_attributes
    # Remove upgrade required "state"
    if plan_id? && pending_plan_id? && Plan.find(plan_id).upgrade?(Plan.find(pending_plan_id))
      self.first_plan_upgrade_required_alert_sent_at = nil
    end

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
    # self.pending_plan_started_at_will_change! if pending_plan_started_at?

    self.save_skip_pwd
  end

private

  # before_save
  def set_trial_started_at
    self.trial_started_at = Time.now.utc if !trial_started_at? && in_or_will_be_in_paid_plan?
  end

  # before_save
  def set_first_paid_plan_started_at
    self.first_paid_plan_started_at = Time.now.utc if trial_ended? && !first_paid_plan_started_at? && pending_plan_id_changed? && will_be_in_paid_plan?
  end

  # after_save (BEFORE_SAVE TRIGGER AN INFINITE LOOP SINCE invoice.save also saves self)
  def create_and_charge_invoice
    if trial_ended? && (activated? || upgraded? || renewed?)
      invoice = ::Invoice.construct(site: self, renew: renewed?)
      invoice.save!

      if instant_charging? && !invoice.paid?
        @transaction = Transaction.charge_by_invoice_ids([invoice.id], { ip: remote_ip })
      end

    elsif pending_plan_id_changed? && pending_plan_id? && (pending_plan.unpaid_plan? || trial_not_started_or_in_trial?)
      # directly update for unpaid plans or any plans during trial
      self.apply_pending_attributes
    end
  end

  # after_save
  def send_trial_started_email
    BillingMailer.trial_has_started(self).deliver!
  end

  # ========================
  # = Dirty state checkers =
  # ========================

  def activated?
    first_paid_plan_started_at_changed? && first_paid_plan_started_at_was.nil?
  end

  def upgraded?
    plan_id? && pending_plan_id_changed? && will_be_in_paid_plan? && plan.upgrade?(pending_plan)
  end

  def renewed?
    !!(
      # the site must already be in a paid plan and not activated just now
      in_paid_plan? && !first_paid_plan_started_at_changed? &&
      !plan.upgrade?(pending_plan) &&
      pending_plan_cycle_started_at_changed? && pending_plan_cycle_started_at?
    )
  end

end
