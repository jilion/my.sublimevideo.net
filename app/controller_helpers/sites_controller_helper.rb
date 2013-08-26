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

  def _set_sites
    @sites ||= current_user.sites.not_archived
  end

  def _set_sites_or_redirect_to_new_site
    if user_signed_in?
      _set_sites

      if @sites.empty?
        redirect_to(assistant_new_site_path, flash: flash)
      else
        @sites.map! { |site| exhibit(site) }
      end
    end
  end

  def _set_site
    return if public_page?

    @site = if demo_site?
      Site.where(token: SiteToken[:www]).first!
    else
      current_user.sites.not_archived.where(token: params[:site_id] || params[:id]).first!
    end
    @site = exhibit(@site)
  end

end
