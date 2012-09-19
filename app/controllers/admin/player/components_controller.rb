require_dependency 'player/component_updater'

class Admin::Player::ComponentsController < Admin::PlayerController
  respond_to :html, only: [:show, :update]
  respond_to :json

  # GET /player/components
  def index
    @components = Player::Component.order{ created_at.desc }
    respond_with(@components)
  end

  # GET /player/components/:id (token)
  def show
    @components = Player::Component.order(:name)
    @component = Player::Component.find_by_token!(params[:id])
    respond_with(@component)
  end

  # POST /player/components
  def create
    @component = Player::Component.new(params[:component])
    @component.save!
    respond_with(@component)
  end

  # PUT /player/components/:id (token)
  def update
    @component = Player::Component.find_by_token!(params[:id])
    Player::ComponentUpdater.update(@component, params[:component])
    respond_with(@component, location: [:admin, @component])
  end

  # DELETE /player/components/:id (token)
  def destroy
    @component = Player::Component.find_by_token!(params[:id])
    @component.destroy
    respond_with(@component)
  end

end
