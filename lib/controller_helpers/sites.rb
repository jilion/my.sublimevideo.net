module ControllerHelpers
  module Sites

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

    def find_sites_or_redirect_to_new_site
      @sites = current_user.sites.not_archived

      redirect_to [:new, :site], flash: flash if @sites.empty?
    end

    def find_site_by_token!
      return if public_page?

      if demo_site?
        @site = Site.find_by_token!(SiteToken[:www])
      else
        @site = current_user.sites.not_archived.find_by_token!(params[:site_id] || params[:id])
      end
      @site = exhibit(@site)
      set_stage_cookie
    end

  end
end
