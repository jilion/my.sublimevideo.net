class Api::SitesController < Api::ApisController
  # self.responder.send(:include, Responders::HttpCacheResponder)

  before_filter :find_by_token!, only: [:show, :usage]

  # GET /sites
  def index
    @sites = current_user.sites.not_archived.includes(:plan, :next_cycle_plan)

    respond_with(@sites, api_template: api_template, root: :sites)
  end

  # GET /sites/:id
  def show
    respond_with(@site, api_template: api_template)
  end

  # GET /sites/:id/usage
  def usage
    respond_with(@site, api_template: api_template(:private, :usage))
  end

  private

  def find_by_token!
    @site = current_user.sites.not_archived.find_by_token!(params[:id])
  rescue ActiveRecord::RecordNotFound
    body = { status: 404, error: "Site with token '#{params[:id]}' could not be found." }
    render(request.format.ref => body, status: 404)
  end

end
