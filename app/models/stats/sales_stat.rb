module Stats
  class SalesStat
    include Mongoid::Document
    include Mongoid::Timestamps

    store_in collection: 'sales_stats'

    field :d, type: DateTime # Day
    field :ne, type: Hash    # new sales { "plus" => { "m" => 3, "y" => 4 }, "premium" => { "m" => 3, "y" => 4 } }
    field :re, type: Hash    # renew sales { "plus" => { "m" => 3, "y" => 4 }, "premium" => { "m" => 3, "y" => 4 } }

    index d: 1
    index created_at: 1

    # send time as id for backbonejs model
    def as_json(options = nil)
      json = super
      json['id'] = d.to_i
      json
    end

    # =================
    # = Class Methods =
    # =================

    class << self

      def json(from = nil, to = nil)
        json_stats = if from.present?
          between(d: from..(to || Time.now.utc.midnight))
        else
          scoped
        end

        json_stats.order_by(d: 1).to_json(only: [:ne, :re])
      end

      def create_stats
        last_stat_day = determine_last_stat_day

        while last_stat_day < 1.day.ago.midnight do
          last_stat_day += 1.day
          create_sales_stat(last_stat_day)
        end
      end

      def determine_last_stat_day
        if SalesStat.present?
          SalesStat.order_by(d: 1).last.try(:d)
        else
          (Invoice.paid.order{ paid_at.asc }.first.paid_at).midnight - 1.day
        end
      end

      def create_sales_stat(day)
        self.create(sales_hash(day))
      end

      def sales_hash(day)
        invoices = Invoice.includes(:invoice_items).paid.between(paid_at: day.beginning_of_day..day.end_of_day)
        hash = {
          d: day.to_time,
          ne: Hash.new { |h,k| h[k] = Hash.new(0) },
          re: Hash.new { |h,k| h[k] = Hash.new(0) }
        }

        invoices.each do |invoice|
          deduction_amount_per_item = if invoice.balance_deduction_amount > 0
            invoice.balance_deduction_amount / invoice.invoice_items.size
          else
            0
          end
          first_key = invoice.renew? ? :re : :ne

          invoice.invoice_items.each do |invoice_item|
            third_key = invoice_item.item.name
            second_key = case invoice_item.type
                         when 'InvoiceItem::AppDesign'
                           'design'
                         when 'InvoiceItem::AddonPlan'
                           invoice_item.item.addon.name
                         when 'InvoiceItem::Plan'
                           third_key = invoice_item.item.cycle[0]
                           invoice_item.item.name
                         end
            hash[first_key][second_key][third_key] += invoice_item.amount - deduction_amount_per_item
          end
        end

        hash
      end

    end

  end
end
