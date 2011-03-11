module Site::Invoice

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

  def in_or_was_in_paid_plan?
    (new_record? && in_paid_plan?) ||
    (plan_id_changed? && plan_id_was && !Plan.find(plan_id_was).dev_plan?) ||
    (!plan_id_changed? && in_paid_plan?)
  end

  # before_save :if => :plan_id_changed?
  def update_cycle_plan
    self.plan            = next_cycle_plan || plan
    self.next_cycle_plan = nil

    # update plan_started_at
    if plan_id_changed?
      if plan_cycle_ended_at && plan_cycle_ended_at < Time.now.utc # Downgrade
        self.plan_started_at = plan_cycle_ended_at.tomorrow.midnight
      else # Upgrade or from Dev plan
        self.plan_started_at = plan_cycle_started_at || Time.now.utc.midnight
      end
    end
    # update plan_cycle_started_at & plan_cycle_ended_at
    if plan.dev_plan?
      self.plan_cycle_started_at = nil
      self.plan_cycle_ended_at   = nil
    elsif plan_id_changed? || plan_cycle_ended_at.nil? || plan_cycle_ended_at < Time.now.utc
      self.plan_cycle_started_at = (plan_started_at + months_since_plan_started_at.months).midnight
      self.plan_cycle_ended_at   = (plan_started_at + advance_for_next_cycle_end(plan)).to_datetime.end_of_day
    end
    true # don't block the callbacks chain
  end

private

  # ====================
  # = Instance Methods =
  # ====================

  def months_since_plan_started_at
    now = Time.now.utc
    if plan_started_at && (now - plan_started_at >= 1.month)
      months = now.month - plan_started_at.month
      months -= 1 if months > 0 && (now.day - plan_started_at.day) < 0

      (now.year - plan_started_at.year) * 12 + months
    else
      0
    end
  end

  def advance_for_next_cycle_end(plan)
    if plan.yearly?
      (months_since_plan_started_at + 12).months
    else
      (months_since_plan_started_at + 1).months
    end - 1.day
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