class Stat

  module SiteUsage
    class << self

      def timeline(start_date, end_date, options={})
        labels = options[:labels] || labels_to_fields_mapping.keys
        conditions = {
          :day => {
            "$gte" => start_date.to_date.to_time.midnight,
            "$lte" => end_date.to_date.to_time.end_of_day
          }
        }
        conditions[:site_id] = options[:site_id].to_i if options[:site_id]

        usages = ::SiteUsage.collection.group(
          [:day],
          conditions,
          {
            :loader_usage => 0,
            :invalid_usage => 0, :invalid_usage_cached => 0,
            :dev_usage => 0, :dev_usage_cached => 0,
            :extra_usage => 0, :extra_usage_cached => 0,
            :main_usage => 0, :main_usage_cached => 0,
            :all_usage => 0
          }, # memo variable name and initial value
          reduce(labels, options[:merge_cached])
        )

        # insert empty hash for days without usage
        usages = (start_date.to_date..end_date.to_date).inject([]) do |memo, day|
          memo << (usages.detect { |u| u["day"].to_date == day } || { "day" => day })
        end

        labels.inject({}) do |memo, type|
          memo[type.to_s]       = usages.map { |u| u[type.to_s].to_i }
          memo["total_#{type}"] = memo[type.to_s].inject([]) { |memo, u| memo << ((memo.last || 0) + u) }
          memo
        end
      end

      def reduce(labels, merge_cached = false)
        labels.inject("function(doc, prev) {") do |js,label|
          js += "prev.#{label} += doc.#{labels_to_fields_mapping[label.to_sym]}#{" + doc.#{labels_to_fields_mapping[label.to_sym]}_cached" if merge_cached};"
        end + "}"
      end

      def labels_to_fields_mapping
        {
          loader_usage: 'loader_hits',
          invalid_usage: 'invalid_player_hits',
          invalid_usage_cached: 'invalid_player_hits_cached',
          dev_usage: 'dev_player_hits',
          dev_usage_cached: 'dev_player_hits_cached',
          extra_usage: 'extra_player_hits',
          extra_usage_cached: 'extra_player_hits_cached',
          main_usage: 'main_player_hits',
          main_usage_cached: 'main_player_hits_cached',
          all_usage: 'player_hits'
        }
      end

    end
  end

  module Invoice
    class << self

      def timeline(start_date, end_date, options={})
        conditions = options[:user_id] ? { user_id: options[:user_id].to_i } : {}
        invoices = ::Invoice.where(conditions).between(start_date, end_date)
        invoices.group_by(&:ended_at).inject([]) do |data, h|
          data << h[1].inject(0) { |sum, grouped_invoices| sum += grouped_invoices.amount }
        end
      end

    end
  end

end
