module SitesControllerHelper

  def demo_site?
    params[:site_id] == 'demo'
  end

  def public_page?
    params[:site_id] == 'public'
  end

  def self.included(base)
    if base.respond_to?(:helper_method)
      base.send :helper_method, :demo_site?
      base.send :helper_method, :public_page?
    end
  end

  def find_sites
    @sites ||= current_user.sites.not_archived
  end

  def find_sites_or_redirect_to_new_site
    if user_signed_in?
      find_sites

      if @sites.empty?
        redirect_to(assistant_new_site_path, flash: flash)
      else
        @sites.map! { |site| exhibit(site) }
      end
    end
  end

  def find_site_by_token!
    return if public_page?

    @site = if demo_site?
      Site.find_by_token!(SiteToken[:www])
    else
      current_user.sites.not_archived.find_by_token!(params[:site_id] || params[:id])
    end
    @site = exhibit(@site)
    set_stage_cookie
  end

end
