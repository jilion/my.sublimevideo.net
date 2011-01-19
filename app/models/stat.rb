module Stat

  class SiteUsage

    def initialize(start_date, end_date, options={})
      @start_date       = start_date
      @end_date         = end_date
      @options          = options
      @labels_to_fields = options[:labels] ? labels_to_fields.select { |k, v| @options[:labels].include?(k) } : labels_to_fields
    end

    def self.timeline(start_date, end_date, options={})
      new(start_date, end_date, options).timeline
    end

    # Used to display a site usages chart
    #
    # Params:
    # * start_date: site_usages' day field must be >= this date
    # * end_date: site_usages' day field must be < this date
    # * options: Hash
    #   - site_ids: an array of sites' ids to restrict the selected invoices
    #   - labels: can be used to override labels, restrict usage fields retrieved.
    #   default labels are: loader_usage, invalid_usage, invalid_usage_cached, dev_usage, dev_usage_cached,
    #                       extra_usage, extra_usage_cached, main_usage, main_usage_cached, all_usage
    #   - merge_cached: addition fields with their 'cached' counterpart. e.g. main_usage + main_usage_cached
    #
    # Return a hash of site usages. Default keys of the hash are the default labels (see the 'labels' options):
    def timeline
      conditions = {
        :day => {
          "$gte" => @start_date.to_date.to_time.midnight,
          "$lte" => @end_date.to_date.to_time.end_of_day
        }
      }
      conditions[:site_id] = { "$in" => @options[:site_ids] } if @options[:site_ids]

      usages = ::SiteUsage.collection.group(
        :key => [:day],
        :conditions => conditions,
        :initial => {
          :loader_usage => 0,
          :invalid_usage => 0, :invalid_usage_cached => 0,
          :dev_usage => 0, :dev_usage_cached => 0,
          :extra_usage => 0, :extra_usage_cached => 0,
          :main_usage => 0, :main_usage_cached => 0,
          :all_usage => 0
        }, # memo variable name and initial value
        :reduce => reduce
      )

      total = total_usages_before_start_date

      # insert empty hash for days without usage
      usages = (@start_date.to_date..@end_date.to_date).inject([]) do |memo, day|
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

    def total_usages_before_start_date
      conditions = { :day => { "$lt" => @start_date.to_date.to_time.midnight } }
      conditions[:site_id] = { "$in" => @options[:site_ids] } if @options[:site_ids]

      usages = ::SiteUsage.collection.group(
        :key => nil,
        :conditions => conditions,
        :initial => {
          :loader_usage => 0,
          :invalid_usage => 0, :invalid_usage_cached => 0,
          :dev_usage => 0, :dev_usage_cached => 0,
          :extra_usage => 0, :extra_usage_cached => 0,
          :main_usage => 0, :main_usage_cached => 0,
          :all_usage => 0
        }, # memo variable name and initial value
        :reduce => reduce
      )
    end

    def reduce
      @labels_to_fields.keys.inject("function(doc, prev) {\n") do |js, label|
        js += "\tprev.#{label} += doc.#{@labels_to_fields[label]}"
        if @options[:merge_cached] && [:loader_usage, :all_usage].exclude?(label)
          js += "#{" + doc.#{@labels_to_fields[label]}_cached"}"
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

  class Invoice

    # Used to display an invoices chart
    #
    # Params:
    # * start_date: invoices must be >= this date
    # * end_date: invoices must be <= this date
    # * options: Hash
    #   - user_id: id of a user to restrict the selected invoices
    #
    # Return a array of invoices.
    def self.timeline(start_date, end_date, options={})
      conditions = options[:user_id] ? { user_id: options[:user_id].to_i } : {}
      invoices = ::Invoice.where(conditions).between(start_date, end_date)
      invoices.order(:ended_at.asc)#group_by(&:ended_at).inject([]) do |data, h|
      #   data << h[1].inject(0) { |sum, grouped_invoices| sum += grouped_invoices.amount }
      # end
    end

  end

end
