class Admin::Player::ComponentVersionsController < Admin::PlayerController
  respond_to :zip, only: [:show]
  respond_to :html, only: [:destroy]
  respond_to :json

  before_filter :find_component

  # GET /player/components/:component_id/versions
  def index
    @versions = @component.versions
    respond_with(@versions)
  end

  # GET /player/components/:component_id/versions/:id
  def show
    @version = @component.versions.find_by_version!(params[:id])
    respond_with(@version) do |format|
      format.zip { redirect_to @version.zip.url }
    end
  end

  # POST /player/components/:component_id/versions
  def create
    @version = @component.versions.build(params[:component])
    @version.save!
    respond_with(@version)
  end

  # DELETE /player/components/:component_id/versions/:id
  def destroy
    @version = @component.versions.find_by_version!(params[:id])
    @version.destroy
    respond_with(@version, location: [:admin, @component])
  end

private

  def find_component
    @component = Player::Component.find_by_token!(params[:component_id])
  end

end
