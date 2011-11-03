module SiteModules::Invoice
  extend ActiveSupport::Concern

  module ClassMethods

    def activate_or_downgrade_sites_leaving_trial
      Site.not_in_trial.billable.where(first_paid_plan_started_at: nil).find_each(:batch_size => 100) do |site|
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

    %w[trial_started_at stats_trial_started_at first_paid_plan_started_at pending_plan_started_at pending_plan_cycle_started_at].each do |attr|
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

    def trial_not_started_or_in_trial?
      !trial_started_at? || trial_started_at > BusinessModel.days_for_trial.days.ago
    end

    # DEPRECATED, TO BE REMOVED 30 DAYS AFTER NEW BUSINESS MODEL DEPLOYMENT
    def refundable?
      first_paid_plan_started_at? && first_paid_plan_started_at > BusinessModel.days_for_refund.days.ago && !refunded_at?
    end

    def refunded?
      archived? && refunded_at?
    end

    def plan_cycle_ended?
      plan_cycle_ended_at? && plan_cycle_ended_at < Time.now.utc
    end

    def months_since(time)
      if time
        now     = Time.now.utc
        months  = (now.year - time.year) * 12
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

    def advance_for_next_cycle_end(plan, start_time = plan_started_at)
      offset = months_since(start_time)
      offset = offset - (offset % 12) + 11 if plan.yearly?

      (offset + 1).months - 1.day
    end

    def trial_end
      trial_started_at? ? trial_started_at + BusinessModel.days_for_trial.days : nil
    end

    def last_paid_invoice
      invoices.paid.order(:paid_at).try(:last)
    end

    def last_paid_plan_price
      last_paid_invoice ? last_paid_invoice.plan_invoice_items.find { |pii| pii.amount > 0 }.try(:price) || 0 : 0
    end

    # DEPRECATED, TO BE REMOVED 30 DAYS AFTER NEW BUSINESS MODEL DEPLOYMENT
    def refund
      Site.transaction do
        self.touch(:refunded_at)
        Transaction.delay.refund_by_site_id(self.id)
      end
    end

    # before_save :if => :pending_plan_id_changed? / also called from SiteModules::Invoice.renew_active_sites
    def pend_plan_changes
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
         first_paid_plan_started_at_changed? # Activation

        # Downgrade
        if plan_cycle_ended?
          self.pending_plan_started_at = plan_cycle_ended_at.tomorrow

        # Creation, activation or upgrade
        else
          # Upgrade only
          @instant_charging = !trial_not_started_or_in_trial? && !first_paid_plan_started_at_changed?
          # Creation, activation or upgrade
          self.pending_plan_started_at = plan_cycle_started_at || Time.now.utc
        end

        if !trial_not_started_or_in_trial? &&
          (
            # Activation
            first_paid_plan_started_at_changed? ||
            # Upgrade or downgrade
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
    # and from Invoice#succeed's apply_pending_site_plan_changes callback
    def apply_pending_plan_changes
      # Remove upgrade required "state"
      if plan_id? && pending_plan_id? && Plan.find(plan_id).upgrade?(Plan.find(pending_plan_id))
        self.first_plan_upgrade_required_alert_sent_at = nil
      end

      write_attribute(:plan_id, pending_plan_id) if pending_plan_id?

      # force update
      %w[plan_started_at plan_cycle_started_at plan_cycle_ended_at pending_plan_id pending_plan_cycle_started_at pending_plan_cycle_ended_at].each do |attr|
        self.send("#{attr}_will_change!")
      end
      self.pending_plan_started_at_will_change! if pending_plan_started_at?

      self.plan_started_at               = pending_plan_started_at if pending_plan_started_at?
      self.plan_cycle_started_at         = pending_plan_cycle_started_at
      self.plan_cycle_ended_at           = pending_plan_cycle_ended_at

      %w[pending_plan_id pending_plan_started_at pending_plan_cycle_started_at pending_plan_cycle_ended_at].each do |attr|
        self.send("#{attr}=", nil)
      end

      save_without_password_validation
    end

  private

    # before_save
    def set_trial_started_at
      if !trial_started_at? && in_or_will_be_in_paid_plan?
        self.trial_started_at = Time.now.utc
      end
    end

    # after_save (BEFORE_SAVE TRIGGER AN INFINITE LOOP SINCE invoice.save also saves self)
    def create_and_charge_invoice
      if !trial_not_started_or_in_trial? && (activated? || upgraded? || renewed?)
        invoice = ::Invoice.construct(site: self, renew: renewed?)
        invoice.save!

        if instant_charging? && !invoice.paid?
          @transaction = Transaction.charge_by_invoice_ids([invoice.id], charging_options || {})
        end

      elsif pending_plan_id_changed? && pending_plan_id? && (pending_plan.unpaid_plan? || trial_not_started_or_in_trial?)
        # directly update for unpaid plans or any plans during trial
        self.apply_pending_plan_changes
      end
    end

    # ========================
    # = Dirty state checkers =
    # ========================

    def activated?
      first_paid_plan_started_at_changed?
    end

    # Pending plan is a paid plan.
    # Either first paid plan or upgrade between 2 paid plans
    def upgraded?
      plan_id? && plan.upgrade?(pending_plan)
    end

    def renewed?
      !!(
      # the site must already be in a paid plan and not activated just now
      in_paid_plan? && !activated? &&
      !plan.upgrade?(pending_plan) &&
      pending_plan_cycle_started_at_changed? && pending_plan_cycle_started_at?
      )
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
