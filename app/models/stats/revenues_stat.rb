module Stats
  class RevenuesStat
    include Mongoid::Document
    include Mongoid::Timestamps

    store_in collection: 'revenues_stats'

    field :d, type: DateTime # Day
    field :r, type: Hash     # design revenue { "design" => { "html5" => { 999 } }, "logo" => { "custom" => 999 } }

    index d: 1

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

        json_stats.order_by(d: 1).to_json(only: [:r])
      end

      def create_stats
        last_stat_day = determine_last_stat_day

        while last_stat_day < 1.day.ago.midnight do
          last_stat_day += 1.day
          create_revenues_stat(last_stat_day)
        end
      end

      def determine_last_stat_day
        if self.present?
          self.order_by(d: 1).last.try(:d)
        else
          (BillableItemActivity.order{ created_at.asc }.first.created_at).midnight - 1.day
        end
      end

      def create_revenues_stat(day)
        self.create(revenues_hash(day))
      end

      def revenues_hash(day)
        hash = {
          d: day.to_time,
          r: Hash.new { |h,k| h[k] = Hash.new(0) }
        }

        ::Site.not_archived.find_each(batch_size: 100) do |site|
          invoice_service = Service::Invoice.build_for_period((day - 1.day).all_day, site)

          invoice_service.invoice.invoice_items.each do |invoice_item|
            second_key = case invoice_item.type
                        when 'InvoiceItem::AppDesign'
                          'design'
                        when 'InvoiceItem::AddonPlan'
                          invoice_item.item.addon.name
                        end
            third_key = invoice_item.item.name
            hash[:r][second_key][third_key] += invoice_item.amount
          end
        end

        hash
      end

    end

  end
end
