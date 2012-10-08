require_dependency 'vat'

module Service
  Invoice = Struct.new(:invoice) do
    delegate :site, to: :invoice

    class << self
      def build(attributes)
        new attributes.delete(:site).invoices.new(attributes)
      end

      def build_for_month(date, attributes)
        build(attributes).for_month(date)
      end
    end

    def for_month(date)
      last_month_billable_item_activities = site.billable_item_activities.where{ created_at >> date.all_month }

      last_month_billable_item_activities.where(state: 'canceled').each do |activity|
        next if activity.item.free?

        if start_activity = site.billable_item_activities.where(item_type: activity.item_type, item_id: activity.item_id).where{ created_at < activity.created_at }.where(state: 'subscribed').order('created_at DESC').first
          add_invoice_item(build_invoice_item(activity.item, [start_activity.created_at, date.beginning_of_month].max, activity.created_at))
        end
      end

      last_month_billable_item_activities.where(state: 'subscribed').each do |activity|
        next if activity.item.free?

        end_activity = site.billable_item_activities.where(item_type: activity.item_type, item_id: activity.item_id).where{ created_at >> (activity.created_at..date.end_of_month) }.where(state: 'canceled').order('created_at ASC').first
        add_invoice_item(build_invoice_item(activity.item, activity.created_at, end_activity.try(:created_at) || date.end_of_month))
      end

      handle_items_created_before_this_month_and_not_yet_canceled(date)

      # puts invoice.invoice_items.inspect
      self
    end

    def handle_items_created_before_this_month_and_not_yet_canceled(date)
      site.billable_item_activities.where{ created_at < date.beginning_of_month }.where(state: 'subscribed').each do |activity|
        unless site.billable_item_activities.where(item_type: activity.item_type, item_id: activity.item_id).where{ created_at > activity.created_at }.where(state: 'canceled').exists?
          add_invoice_item(build_invoice_item(activity.item, date.beginning_of_month, date.end_of_month))
        end
      end
    end

    def add_invoice_item(invoice_item)
      invoice.invoice_items << invoice_item
    end

    def save
      set_invoice_items_amount
      set_vat_rate_and_amount
      set_balance_deduction_amount
      set_amount

      invoice.save!
    end

    private

    def build_invoice_item(item, started_at, ended_at)
      InvoiceItem.const_get(item.class.to_s.sub(/::/, '')).new({
        invoice: invoice,
        item: item,
        started_at: started_at,
        ended_at: ended_at,
        price: item.price,
        amount: (self.class.full_days(started_at, ended_at) * (item.price.to_f / Time.days_in_month(started_at.month, started_at.year))).round
      }, as: :admin)
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
      invoice.balance_deduction_amount = invoice.site.user.balance > 0 ? [invoice.site.user.balance, invoice.invoice_items_amount].min : 0
    end

    def set_amount
      invoice.amount = invoice.invoice_items_amount + invoice.vat_amount - invoice.balance_deduction_amount
    end

  end
end
