module Site::Invoice
  extend ActiveSupport::Concern

  module ClassMethods

    def activate_or_downgrade_sites_leaving_trial
      Site.not_in_trial.where(first_paid_plan_started_at: nil).each do |site|
        if site.user.credit_card?
          site.first_paid_plan_started_at = Time.now.utc
          site.pend_plan_changes
        else
          site.plan_id = Plan.free_plan.id
        end
        site.save_without_password_validation
      end
    end

    def renew_active_sites
      Site.renewable.each do |site|
        site.pend_plan_changes
        site.save_without_password_validation
      end
    end

  end

  module InstanceMethods

    %w[open failed waiting].each do |invoice_state|
      define_method :"invoices_#{invoice_state}?" do
        invoices.any? { |i| i.send "#{invoice_state}?" }
      end
    end

    %w[free sponsored paid custom].each do |plan_type|
      define_method :"in_#{plan_type}_plan?" do
        plan && plan.send("#{plan_type}_plan?")
      end
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

    def in_trial?
      !trial_started_at? || trial_started_at > BusinessModel.days_for_trial.days.ago
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

    # DEPRECATED, TO BE REMOVED 30 DAYS AFTER NEW BUSINESS MODEL DEPLOYMENT
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
      if (pending_plan_id_changed? && pending_plan_id?) ||
         first_paid_plan_started_at_changed? # site goes out of trial

        # Downgrade
        if plan_cycle_ended_at? && plan_cycle_ended_at < Time.now.utc
          self.pending_plan_started_at = plan_cycle_ended_at.tomorrow.midnight

        # Upgrade or activation after trial ends
        else
          @instant_charging = !in_trial? && !first_paid_plan_started_at_changed? && first_paid_plan_started_at? # upgrade
          self.pending_plan_started_at = plan_cycle_started_at || Time.now.utc.midnight
        end

        if (
            (pending_plan_id? && pending_plan.paid_plan?) ||
            # (plan_id? && plan.paid_plan? && first_paid_plan_started_at_changed?) # site goes out of trial
            first_paid_plan_started_at_changed? # site goes out of trial
           ) && !in_trial?
          self.pending_plan_cycle_started_at = (pending_plan_started_at + months_since(pending_plan_started_at).months).midnight
          self.pending_plan_cycle_ended_at   = (pending_plan_started_at +
                                                advance_for_next_cycle_end(pending_plan || plan, pending_plan_started_at)).to_datetime.end_of_day
        else
          self.pending_plan_cycle_started_at = nil
          self.pending_plan_cycle_ended_at   = nil
        end

      # normal renew
      elsif plan_cycle_ended_at? && plan_cycle_ended_at < Time.now.utc
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
      self.pending_plan_started_at_will_change! if pending_plan_started_at?
      self.pending_plan_cycle_started_at_will_change!
      self.pending_plan_cycle_ended_at_will_change!

      self.plan_started_at               = pending_plan_started_at if pending_plan_started_at?
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
      if !trial_started_at? && in_or_will_be_in_paid_plan?
        self.trial_started_at = Time.now.utc.midnight
      end
    end

    # after_save (BEFORE_SAVE TRIGGER AN INFINITE LOOP SINCE invoice.save also saves self)
    def create_and_charge_invoice
      if !in_trial? && (activated? || changed_to_paid_plan? || renewed?)
        invoice = ::Invoice.build(site: self, renew: renewed?)
        invoice.save!
        @transaction = Transaction.charge_by_invoice_ids([invoice.id], charging_options || {}) if instant_charging?

      elsif pending_plan_id_changed? && pending_plan_id? && (pending_plan.unpaid_plan? || in_trial?)
        # directly update for unpaid plans or any plans during trial
        self.apply_pending_plan_changes
      end
      true
    end

    def activated?
      first_paid_plan_started_at_changed?
    end

    def changed_to_paid_plan?
      pending_plan_id_changed? && will_be_in_paid_plan?
    end

    def renewed?
      in_paid_plan? &&
      (!pending_plan_id? || pending_plan.paid_plan?) &&
      plan_cycle_started_at_was.present? &&
      pending_plan_cycle_started_at_changed? && pending_plan_cycle_started_at?
    end

  end

end



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
