class Admin::Player::ComponentVersionsController < Admin::PlayerController
  respond_to :zip, only: [:show]
  respond_to :html, only: [:destroy]
  respond_to :json

  before_filter :find_component

  # GET /app/components/:component_id/versions
  def index
    @versions = @component.versions
    respond_with @versions
  end

  # GET /app/components/:component_id/versions/:id
  def show
    @version = @component.versions.find_by_version!(params[:id])
    respond_with @version do |format|
      format.zip { redirect_to @version.zip.url }
    end
  end

  # POST /app/components/:component_id/versions
  def create
    @version = @component.versions.build(params[:version])
    @version.save
    respond_with @version, location: admin_player_component_version_url(@component, @version)
  end

  # DELETE /app/components/:component_id/versions/:id
  def destroy
    @version = @component.versions.find_by_version!(params[:id])
    @version.destroy
    respond_with @version, location: admin_player_component_versions_url(@component)
  end

private

  def find_component
    @component = Player::Component.find_by_token!(params[:component_id])
  rescue ActiveRecord::RecordNotFound
    body = { status: 404, error: "Component with token '#{params[:component_id]}' could not be found." }
    render request.format.ref => body, status: 404
  end

end
