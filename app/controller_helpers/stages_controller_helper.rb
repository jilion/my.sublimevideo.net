module StagesControllerHelper

  def current_stage
    if @site
      cookies["stage-#{@site.token}"] || 'stable'
    end
  end

  def stage?(stage_name)
    if @site
      cookies["stage-#{@site.token}"] == stage_name
    end
  end

  def self.included(base)
    if base.respond_to?(:helper_method)
      base.send :helper_method, :current_stage
      base.send :helper_method, :stage?
    end
  end

end
