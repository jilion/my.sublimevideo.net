class Admin::App::ComponentsController < Admin::AppController
  respond_to :html, only: [:show, :update]
  respond_to :json

  # GET /app/components
  def index
    @components = ::App::Component.order { created_at.desc }
    respond_with @components
  end

  # GET /app/components/:id (token)
  def show
    @components = ::App::Component.order(:name)
    @component  = ::App::Component.find_by_token!(params[:id])
    respond_with @component
  end

  # POST /app/components
  def create
    @component = ::App::Component.new(params[:component], as: :admin)
    @component.save
    respond_with @component, location: [:admin, @component]
  end

  # PUT /app/components/:id (token)
  def update
    @component = ::App::Component.find_by_token!(params[:id])
    App::Component.update_attributes(params[:component], as: :admin)
    respond_with @component, location: [:admin, @component]
  end

  # DELETE /app/components/:id (token)
  def destroy
    @component = ::App::Component.find_by_token!(params[:id])
    @component.destroy
    respond_with @component, location: [:admin, :app, :components]
  end
end
