class InvoiceCreator
  attr_accessor :invoice

  def initialize(invoice)
    @invoice = invoice
  end

  def self.create_invoices_for_month(date = 1.month.ago)
    Site.not_archived.find_each(batch_size: 100) do |site|
      delay._create_for_month(date, site.id)
    end
  end

  def self.build_for_month(date, site)
    build_for_period(date.all_month, site)
  end

  def self.build_for_period(period, site)
    _build(site: site).for_period(period)
  end

  def save
    _set_invoice_items_amount
    unless invoice.invoice_items_amount.zero?
      _set_vat_rate_and_amount
      _set_balance_deduction_amount
      _set_amount
      _set_renew

      if invoice.save
        Librato.increment 'invoices.events', source: 'create'
      end
    end
  end

  def for_period(period)
    _handle_items_not_yet_canceled_and_created_before_period(period)
    _handle_items_subscribed_during_period(period)

    self
  end

  private

  def self._create_for_month(date, site_id)
    if site = Site.not_archived.find(site_id)
      build_for_month(date, site).save
    end
  end

  def self._build(attributes)
    new(attributes.delete(:site).invoices.new(attributes))
  end

  def _handle_items_not_yet_canceled_and_created_before_period(period)
    _subscribed_activities_before(period.first).each do |activity|
      end_activity = _end_activity_for_activity(activity, period)

      if !end_activity || period.cover?(end_activity.created_at)
        _build_invoice_item(activity.item, period.first, _end_activity_for_activity(activity, period).try(:created_at) || period.last)
      end
    end
  end

  def _handle_items_subscribed_during_period(period)
    _subscribed_activities_during(period).each do |activity|
      next if activity.item.beta? || activity.item.free?

      _build_invoice_item_unless_overlaping_items(activity, period)
    end
  end

  def _build_invoice_item_unless_overlaping_items(activity, period)
    end_activity_date = _end_activity_for_activity(activity, period).try(:created_at) || period.last

    # Ensure we don't create 2 invoice items with the same item and overlapping periods
    unless invoice.invoice_items.detect { |ii| ii.item == activity.item && ii.started_at < activity.created_at && ii.ended_at >= end_activity_date }
      _build_invoice_item(activity.item, activity.created_at, end_activity_date)
    end
  end

  def _subscribed_activities
    invoice.site.billable_item_activities.state('subscribed').reorder('created_at ASC, item_type ASC, item_id ASC')
  end

  def _subscribed_activities_before(date)
    _subscribed_activities.before(date)
  end

  def _subscribed_activities_during(period)
    _subscribed_activities.during(period)
  end

  def _end_activity_for_activity(activity, period)
    _find_item_for_activity(activity).state(%w[canceled suspended sponsored]).during((activity.created_at..period.last)).order('created_at ASC').first
  end

  def _find_item_for_activity(activity)
    invoice.site.billable_item_activities.with_item(activity.item)
  end

  def _build_invoice_item(item, started_at, ended_at)
    InvoiceItemBuilder.new(invoice, item).build_invoice_item(started_at: started_at, ended_at: ended_at)
  end

  def _set_invoice_items_amount
    invoice.invoice_items_amount = invoice.invoice_items.map(&:amount).sum
  end

  def _set_vat_rate_and_amount
    invoice.vat_rate   = Vat.for_country(invoice.site.user.billing_country)
    invoice.vat_amount = (invoice.invoice_items_amount * invoice.vat_rate).round
  end

  def _set_balance_deduction_amount
    invoice.balance_deduction_amount = if invoice.site.user.balance > 0
      [invoice.site.user.balance, invoice.invoice_items_amount + invoice.vat_amount].min
    else
      0
    end
  end

  def _set_amount
    invoice.amount = invoice.invoice_items_amount + invoice.vat_amount - invoice.balance_deduction_amount
  end

  def _set_renew
    invoice.renew = invoice.site.invoices.not_canceled.any?
  end
end
