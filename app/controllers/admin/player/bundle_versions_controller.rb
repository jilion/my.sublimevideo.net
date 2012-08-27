class Admin::Player::BundleVersionsController < Admin::PlayerController
  respond_to :zip, only: [:show]
  respond_to :html, only: [:destroy]
  respond_to :json

  before_filter :find_bundle

  # GET /player/bundles/:bundle_id/versions
  def index
    @versions = @bundle.versions
    respond_with(@versions)
  end

  # GET /player/bundles/:bundle_id/versions/:id
  def show
    @version = @bundle.versions.find_by_version!(params[:id])
    respond_with(@version) do |format|
      format.zip { redirect_to @version.zip.url }
    end
  end

  # POST /player/bundles/:bundle_id/versions
  def create
    @version = @bundle.versions.build(params[:bundle])
    @version.save!
    respond_with(@version)
  end

  # DELETE /player/bundles/:bundle_id/versions/:id
  def destroy
    @version = @bundle.versions.find_by_version!(params[:id])
    @version.destroy
    respond_with(@version, location: [:admin, @bundle])
  end

private

  def find_bundle
    @bundle = Player::Bundle.find_by_token!(params[:bundle_id])
  end

end
