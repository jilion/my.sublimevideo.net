class SiteExhibit < DisplayCase::Exhibit
  def self.applicable_to?(object)
    object.class.name == 'Site'
  end

  def realtime_stats_active?
    @realtime_stats_active ||= self.addon_plan_is_active?(AddonPlan.get('stats', 'realtime'))
  end

  def eql?(other)
    (self.class == other.class) && (self.to_model == other.to_model)
  end
  alias :== eql?

end
