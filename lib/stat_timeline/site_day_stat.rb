module StatTimeline

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

end
