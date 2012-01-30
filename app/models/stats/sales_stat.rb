module Stats
  class SalesStat
    include Mongoid::Document
    include Mongoid::Timestamps

    store_in :sales_stats

    field :d, type: DateTime # Day
    field :ne, type: Hash    # new sales { "plus" => { "m" => 3, "y" => 4 }, "premium" => { "m" => 3, "y" => 4 } }
    field :re, type: Hash    # renew sales { "plus" => { "m" => 3, "y" => 4 }, "premium" => { "m" => 3, "y" => 4 } }

    index :d
    index :created_at

    # ==========
    # = Scopes =
    # ==========

    scope :between, lambda { |start_date, end_date| where(d: { "$gte" => start_date, "$lt" => end_date }) }

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
          between(from, to || Time.now.utc.midnight)
        else
          scoped
        end

        json_stats.order_by([:d, :asc]).to_json(only: [:ne, :re])
      end

      def delay_create_stats
        unless Delayed::Job.already_delayed?('%Stats::SalesStat%create_stats%')
          delay(run_at: Time.now.utc.tomorrow.midnight).create_stats
        end
      end

      def create_stats
        delay_create_stats

        last_stat_day = determine_last_stat_day

        while last_stat_day < Time.now.utc.midnight do
          create_sales_stat(last_stat_day)
          last_stat_day += 1.day
        end
      end

      def determine_last_stat_day
        if SalesStat.present?
          SalesStat.order_by([:d, :asc]).last.try(:d)
        else
          (Invoice.paid.order(:paid_at.asc).first.paid_at).midnight
        end
      end

      def create_sales_stat(day)
        invoices = Invoice.paid.paid_between(day.beginning_of_day, day.end_of_day)

        self.create(sales_hash(day, invoices))
      end

      def sales_hash(day, invoices)
        hash = {
          d: day.to_time,
          ne: Hash.new { |h,k| h[k] = Hash.new(0) },
          re: Hash.new { |h,k| h[k] = Hash.new(0) }
        }

        invoices.each do |invoice|
          if invoice.renew?
            hash[:re][invoice.paid_plan.name][invoice.paid_plan.cycle[0]] += invoice.amount
          else
            hash[:ne][invoice.paid_plan.name][invoice.paid_plan.cycle[0]] += invoice.amount
          end
        end

        hash
      end

    end

  end
end
