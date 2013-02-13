require_dependency 'vat'

module Service
  Invoice = Struct.new(:invoice) do

    class << self
      def create_invoices_for_month(date = 1.month.ago)
        ::Site.not_archived.find_each(batch_size: 100) do |site|
          delay.create_for_month(date, site.id)
        end
      end

      def create_for_month(date, site_id)
        if site = ::Site.not_archived.find(site_id)
          build_for_month(date, site).save
        end
      end

      def build_for_month(date, site)
        build_for_period(date.all_month, site)
      end

      def build_for_period(period, site)
        build(site: site).for_period(period)
      end

      def build(attributes)
        new(attributes.delete(:site).invoices.new(attributes))
      end
    end

    def for_period(period)
      handle_items_not_yet_canceled_and_created_before_period(period)
      handle_items_subscribed_during_period(period)

      self
    end

    def add_invoice_item(invoice_item)
      invoice.invoice_items << invoice_item unless invoice_item.amount.zero?
    end

    def save
      set_invoice_items_amount
      unless invoice.invoice_items_amount.zero?
        set_vat_rate_and_amount
        set_balance_deduction_amount
        set_amount
        set_renew

        if invoice.save
          Librato.increment 'invoices.events', source: 'create'
        end
      end
    end

    private

    def handle_items_not_yet_canceled_and_created_before_period(period)
      invoice.site.billable_item_activities.with_state_before('subscribed', period.first).reorder('created_at ASC, item_type ASC, item_id ASC').each do |activity|
        end_activity = find_end_activity_for_activity(activity, period)

        if !end_activity || period.cover?(end_activity.created_at)
          add_invoice_item(build_invoice_item(activity.item, period.first, find_end_activity_for_activity(activity, period).try(:created_at) || period.last))
        end
      end
    end

    def handle_items_subscribed_during_period(period)
      invoice.site.billable_item_activities.with_state_during('subscribed', period).reorder('created_at ASC, item_type ASC, item_id ASC').each do |activity|
        next if activity.item.beta? || activity.item.free?

        end_activity_date = find_end_activity_for_activity(activity, period).try(:created_at) || period.last

        # Ensure we don't create 2 invoice items with the same item and overlapping periods
        unless invoice.invoice_items.detect { |ii| ii.item == activity.item && ii.started_at < activity.created_at && ii.ended_at >= end_activity_date }
          add_invoice_item(build_invoice_item(activity.item, activity.created_at, end_activity_date))
        end
      end
    end

    def find_start_activity_for_activity(activity)
      item_for_activity(activity).with_state_before('subscribed', activity.created_at).order('created_at DESC').first
    end

    def find_end_activity_for_activity(activity, period)
      item_for_activity(activity).with_state_during(%w[canceled suspended sponsored], (activity.created_at..period.last)).order('created_at ASC').first
    end

    def item_for_activity(activity)
      invoice.site.billable_item_activities.where(item_type: activity.item_type, item_id: activity.item_id)
    end

    def build_invoice_item(item, started_at, ended_at)
      InvoiceItem.const_get(item.class.to_s.sub(/::/, '')).new({
        invoice: invoice,
        item: item,
        started_at: started_at,
        ended_at: ended_at,
        price: item.price,
        amount: (self.class.full_days(started_at, ended_at) * (item.price.to_f / Time.days_in_month(started_at.month, started_at.year))).round
      }, without_protection: true)
    end

    def self.full_days(started_at, ended_at)
      ((ended_at + 1.second - started_at) / 1.day).floor
    end

    def set_invoice_items_amount
      invoice.invoice_items_amount = invoice.invoice_items.map(&:amount).sum
    end

    def set_vat_rate_and_amount
      invoice.vat_rate   = Vat.for_country(invoice.site.user.billing_country)
      invoice.vat_amount = (invoice.invoice_items_amount * invoice.vat_rate).round
    end

    def set_balance_deduction_amount
      invoice.balance_deduction_amount = if invoice.site.user.balance > 0
        [invoice.site.user.balance, invoice.invoice_items_amount + invoice.vat_amount].min
      else
        0
      end
    end

    def set_amount
      invoice.amount = invoice.invoice_items_amount + invoice.vat_amount - invoice.balance_deduction_amount
    end

    def set_renew
      invoice.renew = invoice.site.invoices.not_canceled.any?
    end

  end
end
