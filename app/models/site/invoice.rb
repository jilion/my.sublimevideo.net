module Site::Invoice

  def self.included(base)
    base.send :extend, ClassMethods
  end

  module ClassMethods

    def renew_active_sites
      Site.renewable.each do |site|
        site.pend_plan_changes
        site.save_without_password_validation
      end
    end

  end

  # ====================
  # = Instance Methods =
  # ====================

  def invoices_failed?
    invoices.any? { |i| i.failed? }
  end

  def invoices_waiting?
    invoices.any? { |i| i.waiting? }
  end

  def invoices_open?(options={})
    scope = invoices
    scope = scope.where(renew: options[:renew]) if options.key?(:renew)
    scope.any? { |i| i.open? }
  end

  def in_free_plan?
    plan && plan.free_plan?
  end

  def in_sponsored_plan?
    plan && plan.sponsored_plan?
  end

  def in_paid_plan?
    plan && plan.paid_plan?
  end

  def in_custom_plan?
    plan && plan.custom_plan?
  end

  def instant_charging?
    @instant_charging
  end

  def in_or_will_be_in_paid_plan?
    in_paid_plan? || will_be_in_paid_plan?
  end

  def will_be_in_free_plan?
    if id = (pending_plan_id || next_cycle_plan_id)
      Plan.find(id).free_plan?
    end
  end

  def will_be_in_paid_plan?
    pending_plan_id? && pending_plan.paid_plan?
  end
  
  def in_trial?
    trial_started_at && trial_started_at > BusinessModel.days_for_trial.days.ago
  end

  # DEPRECATED, TO BE REMOVED 30 DAYS AFTER NEW BUSINESS MODEL DEPLOYMENT
  def refundable?
    first_paid_plan_started_at? && first_paid_plan_started_at > BusinessModel.days_for_refund.days.ago && !refunded_at?
  end

  def refunded?
    archived? && refunded_at?
  end

  def last_paid_invoice
    invoices.paid.order(:paid_at).try(:last)
  end

  def last_paid_plan_price
    last_paid_invoice ? last_paid_invoice.plan_invoice_items.detect { |pii| pii.amount > 0 }.price : 0
  end

  def refund
    Site.transaction do
      self.touch(:refunded_at)
      Transaction.delay.refund_by_site_id(self.id)
    end
  end

  # before_save :if => :pending_plan_id_changed? / also called from Site::Invoice.renew_active_sites
  def pend_plan_changes
    @instant_charging = false

    # Downgrade
    # Test with the pending_plan_cycle_ended_at first in the case where a failed invoice is present
    # so the current plan_cycle_ended_at is not up-to-date, but pending_plan_cycle_ended_at is!
    if next_cycle_plan_id? && ((pending_plan_cycle_ended_at || plan_cycle_ended_at) < Time.now.utc)
      self.pending_plan_id    = next_cycle_plan_id
      self.next_cycle_plan_id = nil
    end

    # new paid plan (creation, upgrade or downgrade)
    if pending_plan_id_changed? && pending_plan_id? # either because of a creation, an upgrade or a downgrade (just changed above)

      # Downgrade
      if plan_cycle_ended_at && plan_cycle_ended_at < Time.now.utc
        self.pending_plan_started_at = plan_cycle_ended_at.tomorrow.midnight

      # Upgrade or creation
      else
        @instant_charging = true
        self.pending_plan_started_at = plan_cycle_started_at || Time.now.utc.midnight
      end

      if pending_plan.paid_plan? && !in_trial?
        self.pending_plan_cycle_started_at = (pending_plan_started_at + months_since(pending_plan_started_at).months).midnight
        self.pending_plan_cycle_ended_at   = (pending_plan_started_at + advance_for_next_cycle_end(pending_plan, pending_plan_started_at)).to_datetime.end_of_day
      else
        self.pending_plan_cycle_started_at = nil
        self.pending_plan_cycle_ended_at   = nil
      end

    elsif plan_cycle_ended_at? && plan_cycle_ended_at < Time.now.utc # normal renew
      self.pending_plan_cycle_started_at = (plan_started_at + months_since(plan_started_at).months).midnight
      self.pending_plan_cycle_ended_at   = (plan_started_at + advance_for_next_cycle_end(plan, plan_started_at)).to_datetime.end_of_day
    end

    true # don't block the callbacks chain
  end

  # called from Site::Invoice.renew_active_sites and from Invoice#succeed's apply_pending_site_plan_changes callback
  def apply_pending_plan_changes
    # Remove upgrade required "state"
    if plan_id? && pending_plan_id? && Plan.find(plan_id).upgrade?(Plan.find(pending_plan_id))
      self.first_plan_upgrade_required_alert_sent_at = nil
    end

    write_attribute(:plan_id, pending_plan_id) if pending_plan_id?

    # force update
    self.plan_started_at_will_change!
    self.plan_cycle_started_at_will_change!
    self.plan_cycle_ended_at_will_change!
    self.pending_plan_id_will_change!
    self.pending_plan_started_at_will_change! if pending_plan_started_at
    self.pending_plan_cycle_started_at_will_change!
    self.pending_plan_cycle_ended_at_will_change!

    self.plan_started_at               = pending_plan_started_at if pending_plan_started_at
    self.plan_cycle_started_at         = pending_plan_cycle_started_at
    self.plan_cycle_ended_at           = pending_plan_cycle_ended_at
    self.pending_plan_id               = nil
    self.pending_plan_started_at       = nil
    self.pending_plan_cycle_started_at = nil
    self.pending_plan_cycle_ended_at   = nil

    save_without_password_validation
  end

  def months_since(time)
    now = Time.now.utc
    if time
      months = (now.year - time.year) * 12
      months += now.month - time.month
      months -= 1 if (now.day - time.day) < 0
      months
    else
      0
    end
  end

  def days_since(time)
    time ? ((Time.now.utc.midnight.to_i - time.midnight.to_i) / 1.day) : 0
  end

  def advance_for_next_cycle_end(plan, start_time=plan_started_at)
    if plan.yearly?
      (months_since(start_time) + 12).months
    else
      (months_since(start_time) + 1).months
    end - 1.day
  end

private

  # before_save
  def set_trial_started_at
    if !trial_started_at? && in_paid_plan?
      self.trial_started_at = Time.now.utc
    end
  end

  # before_save
  def set_first_paid_plan_started_at
    if !first_paid_plan_started_at? && in_paid_plan? && !in_trial?
      self.first_paid_plan_started_at = plan_started_at
    end
  end

  # after_save BEFORE_SAVE TRIGGER AN INFINITE LOOP SINCE invoice.save also saves self
  def create_and_charge_invoice
    if being_changed_to_paid_plan? || being_renewed?
      invoice = Invoice.build(site: self, renew: !!being_renewed?)
      invoice.save!
      @transaction = Transaction.charge_by_invoice_ids([invoice.id], charging_options || {}) if instant_charging?

    elsif pending_plan_id_changed? && pending_plan_id? && pending_plan.unpaid_plan?
      # directly update for unpaid plans
      self.apply_pending_plan_changes
    end
    true
  end

  def being_changed_to_paid_plan?
    pending_plan_id_changed? && will_be_in_paid_plan?
  end

  def being_renewed?
    # ensure plan_cycle dates are set, not nil!
    in_paid_plan? && ((pending_plan_cycle_started_at_changed? && pending_plan_cycle_started_at?) || (pending_plan_cycle_ended_at_changed? && pending_plan_cycle_ended_at?))
  end

end

Site.send :include, Site::Invoice

# == Schema Information
#
# Table name: sites
#
#  first_paid_plan_started_at                 :datetime
#  plan_started_at                            :datetime
#  plan_cycle_started_at                      :datetime
#  plan_cycle_ended_at                        :datetime
#  next_cycle_plan_id                         :integer
#
