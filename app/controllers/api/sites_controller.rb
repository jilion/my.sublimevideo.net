class Api::SitesController < Api::ApiController
  self.responder.send(:include, Responders::HttpCacheResponder)

  before_filter :find_by_token!, :only => [:show, :usage]

  # GET /api/v1/sites
  def index
    @sites = current_api_user.sites.not_archived.includes(:plan, :next_cycle_plan)
    respond_with(@sites) do |format|
      format.json { render_for_api api_template(params[:version]), :json => @sites, :root => :sites }
    end
  end

  # GET /api/v1/sites/:id
  def show
    respond_with(@site) do |format|
      format.json { render_for_api api_template(params[:version]), :json => @site }
    end
  end

  # GET /api/v1/sites/:id/usage
  def usage
    respond_with(@site) do |format|
      format.json { render_for_api api_template(params[:version], :usage), :json => @site }
    end
  end

  private

  def find_by_token!
    @site = current_api_user.sites.not_archived.find_by_token!(params[:id])
  end

end
