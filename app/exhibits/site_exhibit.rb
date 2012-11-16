class SiteExhibit < DisplayCase::Exhibit
  def self.applicable_to?(object)
    object.class.name == 'Site'
  end

  def render_hostname_row(template)
    template.render('sites/td_hostname', site: self)
  end

  def render_usage_row_content(template)
    if realtime_stats_active?
      template.render('sites/td_usage/td_content_with_stats', site: self)
    else
      template.render('sites/td_usage/td_content_without_stats', site: self)
    end
  end

  def render_segmented_menu(template)
    template.render('sites/segmented_menu', site: self)
  end

  def realtime_stats_active?
    @realtime_stats_active ||= self.addon_plan_is_active?(AddonPlan.get('stats', 'realtime'))
  end

  def eql?(other)
    (self.class == other.class) && (self.to_model == other.to_model)
  end
  alias :== eql?

end
