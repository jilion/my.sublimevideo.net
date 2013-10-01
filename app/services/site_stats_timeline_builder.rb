class SiteStatsTimelineBuilder

  def initialize(options = {})
    @options = options
  end

  # Creates d_pv, m_pv, e_pv, em_pv, d_vv, m_vv, e_vv, em_vv,
  # normal_pv, normal_vv, billable_pv, billable_vv methods
  %w[p v].each do |view_type|
    %w[d m e em].each do |field|
      define_method("#{field}_#{view_type}v") do
        _all.map { |s| s["#{view_type}v"][field].to_i }
      end
    end

    %w[normal billable].each do |type|
      define_method("#{type}_#{view_type}v") do
        send("_#{type}_views", view_type)
      end
    end
  end

  private

  def _all
    []
    # @_all ||= Stat::Site::Day.last_stats(@options)
  end

  def _sum_views(type, view_types)
    _all.map do |s|
      view_types.inject(0) { |sum, view_type| sum += s["#{type}v"][view_type].to_i }
    end
  end

  def _normal_views(type)
    _sum_views(type, %w[m e])
  end

  def _billable_views(type)
    _sum_views(type, %w[m e em])
  end

end
