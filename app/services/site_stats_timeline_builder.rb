class SiteStatsTimelineBuilder

  def initialize(options = {})
    @options = options
  end

  # Creates d_pv, m_pv, e_pv, em_pv, d_vv, m_vv, e_vv, em_vv methods
  %w[pv vv].each do |type|
    %w[d m e em].each do |field|
      define_method("#{field}_#{type}") do
        _all.map { |s| s[type][field].to_i }
      end
    end
  end

  %w[p v].each do |view_type|
    %w[normal billable].each do |type|
      define_method("#{type}_#{view_type}v") do
        send("_#{type}_views", view_type)
      end
    end
  end

  private

  def _normal_views(type)
    _all.map { |s| s["#{type}v"]['m'].to_i + s["#{type}v"]['e'].to_i }
  end

  def _billable_views(type)
    _all.map { |s| s["#{type}v"]['m'].to_i + s["#{type}v"]['e'].to_i + s["#{type}v"]['em'].to_i }
  end

  def _all
    @_all ||= Stat::Site::Day.last_stats(@options)
  end

end
