class SiteExhibit < DisplayCase::Exhibit
  def self.applicable_to?(object, context)
    object.class.name == 'Site'
  end

  def realtime_stats_active?
    @realtime_stats_active ||= self.subscribed_to?(AddonPlan.get('stats', 'realtime'))
  end

  def eql?(other)
    (self.class == other.class) && (self.to_model == other.to_model)
  end
  alias :== eql?

end
