class Api::SitesController < Api::ApiController
  self.responder.send(:include, Responders::HttpCacheResponder)

  before_filter :find_by_token!, :only => [:show, :usage]

  # GET /api/v1/sites
  def index
    @sites = current_user.sites.not_archived.includes(:plan, :next_cycle_plan)
    render_for_api api_template, request.format.ref => @sites, :root => :sites
  end

  # GET /api/v1/sites/:id
  def show
    render_for_api api_template, request.format.ref => @site
  end

  # GET /api/v1/sites/:id/usage
  def usage
    render_for_api api_template(:private, :usage), request.format.ref => @site
  end

  private

  def find_by_token!
    @site = current_user.sites.not_archived.find_by_token!(params[:id])
  rescue ActiveRecord::RecordNotFound
    response = { error: "Site with token '#{params[:id]}' could not be found." }
    render(request.format.ref => response, status: 404)
  end

end
