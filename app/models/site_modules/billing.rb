require_dependency 'business_model'

module SiteModules::Billing
  extend ActiveSupport::Concern

  %w[open failed waiting].each do |invoice_state|
    define_method :"invoices_#{invoice_state}?" do
      invoices.any? { |i| i.send("#{invoice_state}?") }
    end
  end

  %w[trial free sponsored custom paid unpaid].each do |plan_name|
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

  def will_be_in_unpaid_plan?
    pending_plan_id? && pending_plan.unpaid_plan?
  end

  def in_or_will_be_in_paid_plan?
    in_paid_plan? || will_be_in_paid_plan?
  end

  def refunded?
    archived? && refunded_at?
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

private

  # before_save
  def set_first_paid_plan_started_at
    self.first_paid_plan_started_at = Time.now.utc if !first_paid_plan_started_at? && in_or_will_be_in_paid_plan?
  end

  # after_save
  def send_trial_started_email
    BillingMailer.delay.trial_has_started(id)
  end

  # after_save (BEFORE_SAVE TRIGGER AN INFINITE LOOP SINCE invoice.save also saves self)
  def create_and_charge_invoice
    if updated_to_paid_plan? || renewed?
      invoice = ::Invoice.construct(site_id: self.id, renew: renewed?)
      invoice.save!

      if !invoice.paid? && (created? || upgraded?)
        @transaction = Transaction.charge_by_invoice_ids([invoice.id], { ip: remote_ip })
      end

    # directly update for unpaid plans
    elsif updated_to_unpaid_plan?
      self.apply_pending_attributes
    end
  end

  # ========================
  # = Dirty state checkers =
  # ========================

  def updated_to_paid_plan?
    pending_plan_id_changed? && will_be_in_paid_plan?
  end

  def created?
    plan_id.nil?
  end

  def upgraded?
    plan_id? && pending_plan_id? && plan.upgrade?(pending_plan)
  end

  def renewed?
    !!(
      in_paid_plan? && # already in a paid plan
      (!pending_plan_id? || !plan.upgrade?(pending_plan)) && # no plan change or downgrade
      pending_plan_cycle_started_at_changed? && plan_cycle_started_at_was && pending_plan_cycle_started_at?
    )
  end

  def updated_to_unpaid_plan?
    pending_plan_id_changed? && will_be_in_unpaid_plan?
  end

end
