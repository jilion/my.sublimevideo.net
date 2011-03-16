module Site::Invoice

  def self.included(base)
    base.send :extend, ClassMethods
  end

  module ClassMethods
    # Recurring task
    def delay_renew_active_sites
      unless Delayed::Job.already_delayed?('%Site%renew_active_sites%')
        delay(:priority => 3, :run_at => Time.now.utc.tomorrow.midnight).renew_active_sites
      end
    end

    def renew_active_sites
      Site.active.to_be_renewed.each do |site|
        site.update_cycle_plan
        site.save!
      end
      delay_renew_active_sites
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

  def in_paid_plan?
    plan && plan.paid_plan?
  end

  def instant_charging?
    @instant_charging == true
  end

  def in_or_was_in_paid_plan?
    (new_record? && in_paid_plan?) ||
    (plan_id_changed? && plan_id_was && !Plan.find(plan_id_was).dev_plan?) ||
    (!plan_id_changed? && in_paid_plan?)
  end

  # before_save :if => :plan_id_changed?
  def update_cycle_plan
    @instant_charging = false
    if next_cycle_plan_id?
      write_attribute(:plan_id, next_cycle_plan_id)
      self.next_cycle_plan = nil
    end

    # update plan_started_at
    if plan_id_changed?
      if plan_cycle_ended_at && plan_cycle_ended_at < Time.now.utc # Downgrade
        self.plan_started_at = plan_cycle_ended_at.tomorrow.midnight
      else # Upgrade or creation
        @instant_charging = true
        self.plan_started_at = plan_cycle_started_at || Time.now.utc.midnight
      end
    end
    # update plan_cycle_started_at & plan_cycle_ended_at
    if plan.dev_plan?
      self.plan_cycle_started_at = nil
      self.plan_cycle_ended_at   = nil
    elsif plan_id_changed? || plan_cycle_ended_at.nil? || plan_cycle_ended_at < Time.now.utc
      self.plan_cycle_started_at = (plan_started_at + months_since(plan_started_at).months).midnight
      self.plan_cycle_ended_at   = (plan_started_at + advance_for_next_cycle_end(plan)).to_datetime.end_of_day
    end
    true # don't block the callbacks chain
  end

  def months_since(time)
    now = Time.now.utc
    if time && (now - time >= 1.month)
      months = now.month - time.month
      months += (now.year - time.year) * 12
      months -= 1 if (time.day - now.day) > 0
      months
    else
      0
    end
  end

private

  # ====================
  # = Instance Methods =
  # ====================

  def advance_for_next_cycle_end(plan)
    if plan.yearly?
      (months_since(plan_started_at) + 12).months
    else
      (months_since(plan_started_at) + 1).months
    end - 1.day
  end

  # after_save
  def create_invoice
    if in_paid_plan? && (plan_id_changed? || plan_cycle_started_at_changed? || plan_cycle_ended_at_changed?)
      invoice = Invoice.build(site: self)
      invoice.save!
    end
    if invoice && instant_charging?
      transaction = Transaction.charge_by_invoice_ids([invoice.id])
      if transaction.failed?
        self.errors.add(:base, transaction.error) # Acceptance test needed
        false
      end
    end

    # if in_paid_plan? && (plan_id_changed? || plan_cycle_started_at_changed? || plan_cycle_ended_at_changed?)
    #   invoice = Invoice.build(site: self)
    #   invoice.save!
    # end
    # if @instant_charging
    #   transaction = Transaction.charge_by_invoice_ids([invoice.id])
    #   if transaction.failed?
    #     self.errors.add(:base, transaction.error) # Acceptance test needed
    #   end
    # end
  end

end

Site.send :include, Site::Invoice

# == Schema Information
#
# Table name: sites
#
#  plan_started_at                            :datetime
#  plan_cycle_started_at                      :datetime
#  plan_cycle_ended_at                        :datetime
#  next_cycle_plan_id                         :integer
#
