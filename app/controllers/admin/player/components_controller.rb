class Admin::Player::ComponentsController < Admin::PlayerController
  respond_to :html, only: [:show, :update]
  respond_to :json

  # GET /app/components
  def index
    @components = Player::Component.order{ created_at.desc }
    respond_with @components
  end

  # GET /app/components/:id (token)
  def show
    @components = Player::Component.order(:name)
    @component = Player::Component.find_by_token!(params[:id])
    respond_with @component
  end

  # POST /app/components
  def create
    @component = Player::Component.new(params[:component])
    @component.save
    respond_with @component, location: [:admin, @component]
  end

  # PUT /app/components/:id (token)
  def update
    @component = Player::Component.find_by_token!(params[:id])
    Player::Component.update_attributes(params[:component])
    respond_with @component, location: [:admin, @component]
  end

  # DELETE /app/components/:id (token)
  def destroy
    @component = Player::Component.find_by_token!(params[:id])
    @component.destroy
    respond_with @component, location: [:admin, :player, :components]
  end

end
