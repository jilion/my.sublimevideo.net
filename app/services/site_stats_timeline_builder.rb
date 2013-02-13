class SiteStatsTimelineBuilder

  def initialize(options = {})
    @options = options
  end

  # Creates d_pv, m_pv, e_pv, em_pv, d_vv, m_vv, e_vv, em_vv methods
  %w[pv vv].each do |type|
    %w[d m e em].each do |field|
      define_method("#{field}_#{type}") do
        all.map { |s| s[type][field].to_i }
      end
    end
  end

  def normal_pv
    all.map { |s| s['pv']['m'].to_i + s['pv']['e'].to_i }
  end

  def billable_pv
    all.map { |s| s['pv']['m'].to_i + s['pv']['e'].to_i + s['pv']['em'].to_i }
  end

  def normal_vv
    all.map { |s| s['vv']['m'].to_i + s['vv']['e'].to_i }
  end

  def billable_vv
    all.map { |s| s['vv']['m'].to_i + s['vv']['e'].to_i + s['vv']['em'].to_i }
  end

  private

  def all
    @all ||= Stat::Site::Day.last_stats(@options)
  end
end
