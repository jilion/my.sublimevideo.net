require_dependency 'vat'

module Service
  Invoice = Struct.new(:invoice) do
    delegate :site, to: :invoice

    class << self
      def build(attributes)
        new attributes.delete(:site).invoices.new(attributes)
      end

      def build_for_month(date, site_id)
        build(site: ::Site.find(site_id)).for_month(date)
      end

      def create_invoices_for_month(date = 1.month.ago)
        ::Site.not_archived.find_each(batch_size: 100) do |site|
          delay.create_for_month(date, site.id)
        end
      end

      def create_for_month(date, site_id)
        build_for_month(date, site_id).save
      end
    end

    def for_month(date)
      handle_items_not_yet_canceled_and_created_before_month_of(date)
      handle_items_subscribed_during_month_of(date)

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

        invoice.save
      end
    end

    private

    def find_start_activity_for_activity(activity)
      item_for_activity(activity).where{ created_at < activity.created_at }.where(state: 'subscribed').order('created_at DESC').first
    end

    def find_end_activity_for_activity(activity, date)
      item_for_activity(activity).where{ created_at >> (activity.created_at..date.end_of_month) }.where(state: %w[canceled suspended sponsored]).order('created_at ASC').first
    end

    def item_for_activity(activity)
      site.billable_item_activities.where(item_type: activity.item_type, item_id: activity.item_id)
    end

    def handle_items_not_yet_canceled_and_created_before_month_of(date)
      site.billable_item_activities.where{ created_at < date.beginning_of_month }.where(state: 'subscribed').order('created_at ASC, item_type ASC, item_id ASC').each do |activity|
        end_activity = find_end_activity_for_activity(activity, date)

        if !end_activity || date.all_month.cover?(end_activity.created_at)
          add_invoice_item(build_invoice_item(activity.item, date.beginning_of_month, find_end_activity_for_activity(activity, date).try(:created_at) || date.end_of_month))
        end
      end
    end

    def handle_items_subscribed_during_month_of(date)
      site.billable_item_activities.where{ created_at >> date.all_month }.where(state: 'subscribed').order('created_at ASC, item_type ASC, item_id ASC').each do |activity|
        next if activity.item.free?

        add_invoice_item(build_invoice_item(activity.item, activity.created_at, find_end_activity_for_activity(activity, date).try(:created_at) || date.end_of_month))
      end
    end

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

    def set_renew
      invoice.renew = site.invoices.not_canceled.any?
    end

  end
end
