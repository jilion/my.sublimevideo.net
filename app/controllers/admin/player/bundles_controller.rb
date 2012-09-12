require_dependency 'player/bundle_updater'

class Admin::Player::BundlesController < Admin::PlayerController
  respond_to :html, only: [:show, :update]
  respond_to :json

  # GET /player/bundles
  def index
    @bundles = Player::Bundle.order{ created_at.desc }
    respond_with(@bundles)
  end

  # GET /player/bundles/:id (token)
  def show
    @bundles = Player::Bundle.order(:name)
    @bundle = Player::Bundle.find_by_token!(params[:id])
    respond_with(@bundle)
  end

  # POST /player/bundles
  def create
    @bundle = Player::Bundle.new(params[:bundle])
    @bundle.save!
    respond_with(@bundle)
  end

  # PUT /player/bundles/:id (token)
  def update
    @bundle = Player::Bundle.find_by_token!(params[:id])
    Player::BundleUpdater.update(@bundle, params[:bundle])
    respond_with(@bundle, location: [:admin, @bundle])
  end

  # DELETE /player/bundles/:id (token)
  def destroy
    @bundle = Player::Bundle.find_by_token!(params[:id])
    @bundle.destroy
    respond_with(@bundle)
  end

end
