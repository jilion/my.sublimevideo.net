module StatsDemoHelper

  def find_site_by_token!
    if demo_site?
      @site  = Site.find_by_token(SiteToken[:www])
      @token = 'demo'
    elsif params[:site_id]
      @site  = current_user.sites.not_archived.find_by_token!(params[:site_id])
      @token = @site.token
    end
  end

  def demo_site?
    params[:site_id] == 'demo'
  end

end
