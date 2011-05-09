class Api::V1::SitesController < Api::ApiController
  respond_to :json

  before_filter :find_by_token!, :only => [:show]

  # GET /api/v1/sites
  def index
    @sites = current_api_user.sites.not_archived.includes(:plan, :next_cycle_plan)
    respond_with(@sites) do |format|
      format.json { render :text => @sites.map(&:to_api).to_json }
    end
  end

  # GET /api/v1/sites/:id
  def show
    respond_with(@site) do |format|
      format.json { render @site.to_api.to_json }
    end
  end

  private

  def find_by_token!
    @site = current_api_user.sites.not_archived.find_by_token!(params[:id])
  end

end
