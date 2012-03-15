module StatTimeline

  class SiteUsage

    def initialize(start_time, end_time, options = {})
      @start_time       = start_time
      @end_time         = end_time
      @options          = options
      @labels_to_fields = options[:labels] ? labels_to_fields.select { |k, v| @options[:labels].include?(k) } : labels_to_fields
      @base_conditions  = @options[:site_ids] ? { site_id: { "$in" => [@options[:site_ids]].flatten } } : {}
    end

    def self.timeline(start_time, end_time, options = {})
      new(start_time, end_time, options).timeline
    end

    # Used to display a site usages chart
    #
    # Params:
    # * start_time: site_usages' day field must be >= this date
    # * end_time: site_usages' day field must be < this date
    # * options: Hash
    #   - site_ids: an array of sites' ids to restrict the selected invoices
    #   - labels: can be used to override labels, restrict usage fields retrieved.
    #   default labels are: loader_usage, invalid_usage, invalid_usage_cached, dev_usage, dev_usage_cached,
    #                       extra_usage, extra_usage_cached, main_usage, main_usage_cached, all_usage
    #   - merge_cached: addition fields with their 'cached' counterpart. e.g. main_usage + main_usage_cached
    #
    # Return a hash of site usages. Default keys of the hash are the default labels (see the 'labels' options):
    def timeline
      usages = ::SiteUsage.collection.group(
        :key => [:day],
        :cond => @base_conditions.merge({
          :day => {
            "$gte" => @start_time.midnight,
            "$lte" => @end_time.end_of_day
          }
        }),
        :initial => @labels_to_fields.keys.inject({}) { |hash, k| hash[k] = 0; hash },
        :reduce => reduce
      )

      # total = @options[:dont_add_total_usages_before_start_time] ? [] : total_usages_before_start_time
      total = [] # legacy

      # insert empty hash for days without usage
      usages = (@start_time.to_date..@end_time.to_date).inject([]) do |memo, day|
        memo << (usages.detect { |u| u["day"].to_date == day } || { "day" => day })
      end

      # cast values to integer
      @labels_to_fields.keys.inject({}) do |memo, type|
        memo[type.to_s]       = usages.map { |u| u[type.to_s].to_i }
        memo["total_#{type}"] = memo[type.to_s].inject([]) { |memo, u| memo << ((memo.last || (total.empty? ? 0 : total[0][type.to_s])).to_i + u) }
        memo
      end
    end

    private

    def total_usages_before_start_time
      ::SiteUsage.collection.group(
        :key => nil,
        :cond => @base_conditions.merge({ :day => { "$lt" => @start_time.to_date.to_time.midnight } }),
        :initial => @labels_to_fields.keys.inject({}) { |hash, k| hash[k] = 0; hash },
        :reduce => reduce
      )
    end

    def reduce
      @labels_to_fields.keys.inject("function(doc, prev) {\n") do |js, label|
        js += "\tprev.#{label} += (isNaN(doc.#{@labels_to_fields[label]}) ? 0 : doc.#{@labels_to_fields[label]})"
        if @options[:merge_cached] && [:loader_usage, :all_usage].exclude?(label)
          js += " + (isNaN(doc.#{@labels_to_fields[label]}_cached) ? 0 : doc.#{@labels_to_fields[label]}_cached)"
        end
        js += ";\n"
      end + "}\n"
    end

    def labels_to_fields
      cached_fields = if @options[:merge_cached]
        {}
      else
        {
          invalid_usage_cached: 'invalid_player_hits_cached',
          dev_usage_cached: 'dev_player_hits_cached',
          extra_usage_cached: 'extra_player_hits_cached',
          main_usage_cached: 'main_player_hits_cached'
        }
      end
      cached_fields.merge({
        loader_usage: 'loader_hits',
        invalid_usage: 'invalid_player_hits',
        dev_usage: 'dev_player_hits',
        extra_usage: 'extra_player_hits',
        main_usage: 'main_player_hits',
        all_usage: 'player_hits'
      })
    end

  end

  class SiteDayStat

    # Used to display a site usages chart
    #
    # @returns a hash of site usages. Default keys of the hash are the default labels (see the 'labels' options):
    def self.timeline(options = {})
      new(options)
    end

    def initialize(options = {})
      @options = options
    end

    # Creates d_pv, m_pv, e_pv, em_pv, i_pv, d_vv, m_vv, e_vv, em_vv, i_vv methods
    %w[pv vv].each do |type|
      %w[d m e em i].each do |field|
        define_method("#{field}_#{type}") do
          all.map { |s| s[type][field].to_i }
        end
      end
    end

    def billable_vv
      all.map { |s| s['vv']['m'].to_i + s['vv']['e'].to_i + s['vv']['em'].to_i }
    end

    private

    def all
      @all ||= ::Stat::Site::Day.last_stats(@options)
    end

  end

  class Invoice

    def self.timeline(invoices, start_time, end_time, options = {})
      invoices = invoices.group_by { |i| i.created_at.to_date }

      (start_time.to_date..end_time.to_date).inject([]) do |amounts, day|
        amounts << (invoices[day] ? invoices[day].sum { |i| i.amount } : 0)
      end
    end

  end

  class UsersStat
    attr_accessor :collection

    delegate :empty?, :to => :collection

    def initialize(start_time, end_time, options = {})
      @start_time, @end_time = start_time, end_time
      @collection = ::Stats::UsersStat.between(@start_time.midnight, @end_time.end_of_day)
    end

    def timeline(attribute)
      (@start_time.to_date..@end_time.to_date).each_with_object([]) do |day, array|
        if users_stat = @collection.detect { |u| u.created_at >= day.midnight && u.created_at < day.end_of_day }
          array << users_stat.states_count[attribute.to_s]
        else
          array << 0
        end
      end
    end

  end

end
