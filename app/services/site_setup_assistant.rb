class SiteSetupAssistant

  STEPS = %w[new_site addons player publish_video summary]

  def self.step_number(step_name)
    STEPS.index(step_name) + 1
  end

  def initialize(site)
    @site = site
  end

  def setup_done?
    current_step == 'summary' || SiteAdminStat.total_admin_starts(@site).nonzero?
  end

  def current_step
    @site.current_assistant_step || 'addons'
  end

  def current_step_number
    self.class.step_number(current_step)
  end

end
