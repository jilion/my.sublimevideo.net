module Site::Invoice

  def self.included(base)
    base.send :extend, ClassMethods
  end

  module ClassMethods
    # Recurring task
    def delay_renew_active_sites!
      unless Delayed::Job.already_delayed?('%Site%renew_active_sites!%')
        delay(:priority => 3, :run_at => Time.now.utc.tomorrow.midnight).renew_active_sites!
      end
    end

    def renew_active_sites!
      Site.active.to_be_renewed.each do |site|
        site.pend_plan_changes
        site.apply_pending_plan_changes!
      end
      delay_renew_active_sites!
    end
  end

  # ====================
  # = Instance Methods =
  # ====================

  def in_dev_plan?
    plan && plan.dev_plan?
  end

  def in_beta_plan?
    plan && plan.beta_plan?
  end
  
  def in_sponsored_plan?
    plan && plan.sponsored_plan?
  end

  def in_paid_plan?
    plan && plan.paid_plan?
  end

  def instant_charging?
    @instant_charging
  end

  def in_or_was_in_paid_plan?
    in_paid_plan? || (pending_plan_id && Plan.find(pending_plan_id).paid_plan?)
  end

  # before_save :if => :pending_plan_id_changed? / also called from Site::Invoice.renew_active_sites!
  def pend_plan_changes
    @instant_charging = false

    # Downgrade
    if next_cycle_plan_id?
      self.pending_plan_id = next_cycle_plan_id
      self.next_cycle_plan_id = nil
    end

    # Update pending_plan_started_at
    if pending_plan_id_changed? && pending_plan_id? # either because of an creation, an upgrade or a downgrade (just changed above)

      # Downgrade
      if plan_cycle_ended_at && plan_cycle_ended_at < Time.now.utc
        self.pending_plan_started_at = plan_cycle_ended_at.tomorrow.midnight

      # Upgrade or creation
      else
        @instant_charging = true
        self.pending_plan_started_at = plan_cycle_started_at || Time.now.utc.midnight
      end
    end

    # update pending_plan_cycle_started_at & pending_plan_cycle_ended_at
    if pending_plan_id_changed? && pending_plan_id? # new paid plan (creation, upgrade or downgrade)
      self.pending_plan_cycle_started_at = !pending_plan.paid_plan? ? nil : (pending_plan_started_at + months_since(pending_plan_started_at).months).midnight
      self.pending_plan_cycle_ended_at   = !pending_plan.paid_plan? ? nil : (pending_plan_started_at + advance_for_next_cycle_end(pending_plan, pending_plan_started_at)).to_datetime.end_of_day

    elsif plan_cycle_ended_at? && plan_cycle_ended_at < Time.now.utc # normal renew
      self.pending_plan_cycle_started_at = (plan_started_at + months_since(plan_started_at).months).midnight
      self.pending_plan_cycle_ended_at   = (plan_started_at + advance_for_next_cycle_end(plan, plan_started_at)).to_datetime.end_of_day
    end

    true # don't block the callbacks chain
  end

  # called from Site::Invoice.renew_active_sites! and from Invoice#succeed's apply_pending_site_plan_changes! callback
  def apply_pending_plan_changes!
    write_attribute(:plan_id, pending_plan_id) if pending_plan_id?

    self.plan_started_at       = pending_plan_started_at       if pending_plan_started_at?
    self.plan_cycle_started_at = pending_plan_cycle_started_at if pending_plan_cycle_started_at?
    self.plan_cycle_ended_at   = pending_plan_cycle_ended_at   if pending_plan_cycle_ended_at?

    self.pending_plan_id               = nil
    self.pending_plan_started_at       = nil
    self.pending_plan_cycle_started_at = nil
    self.pending_plan_cycle_ended_at   = nil

    save_without_password_validation!
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

private

  def advance_for_next_cycle_end(plan, start_time=plan_started_at)
    if plan.yearly?
      (months_since(start_time) + 12).months
    else
      (months_since(start_time) + 1).months
    end - 1.day
  end

  # before_save
  def set_first_paid_plan_started_at
    if (plan_id_changed? || plan_started_at_changed?) && in_paid_plan?
      self.first_paid_plan_started_at ||= plan_started_at
    end
  end

  # after_save BEFORE_SAVE TRIGGER AN INFINITE LOOP SINCE invoice.save also saves self
  def create_and_charge_invoice
    if (pending_plan_id_changed? && pending_plan_id? && pending_plan.paid_plan?) || # upgrade or create
        (in_paid_plan? && ((pending_plan_cycle_started_at_changed? && pending_plan_cycle_started_at?) || (pending_plan_cycle_ended_at_changed? && pending_plan_cycle_ended_at?))) # recurrent (ensure plan_cycle dates are set, not nil!)
      invoice = Invoice.build(site: self)
      invoice.save!
      Transaction.charge_by_invoice_ids([invoice.id], d3d_options || {}) if instant_charging?

    elsif pending_plan_id_changed? && pending_plan_id? && !pending_plan.paid_plan?
      # directly update for free plans
      apply_pending_plan_changes!
    end
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
