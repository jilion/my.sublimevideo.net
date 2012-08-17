module DemoSiteHelper

  def demo_site?
    params[:site_id] == 'demo'
  end

  def self.included(base)
    if base.respond_to?(:helper_method)
      base.send :helper_method, :demo_site?
    end
  end

  def find_site_by_token!
    if demo_site?
      @site  = Site.find_by_token!(SiteToken[:www])
    else
      @site  = current_user.sites.not_archived.find_by_token!(params[:site_id])
    end
  end

end
