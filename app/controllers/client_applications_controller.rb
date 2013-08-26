class ClientApplicationsController < ApplicationController
  before_filter :_restrict_to_jilion_team
  before_filter :_set_client_application, only: [:show, :edit, :update, :destroy]

  # GET /account/applications
  def index
    @applications   = current_user.client_applications
    @authorizations = current_user.tokens.valid
  end

  # GET /account/applications/new
  def new
    @application = ClientApplication.new
  end

  # POST /account/applications
  def create
    @application = current_user.client_applications.build(_client_application_params)
    respond_with(@application) do |format|
      if @application.save
        format.html { redirect_to client_application_url(@application), id: @application.id, notice: 'Application registered successfully.' }
      else
        format.html { render :new }
      end
    end
  end

  # GET /account/applications/:id
  def show
  end

  def edit
  end

  # PUT /account/applications/:id
  def update
    @application.update(_client_application_params)
    respond_with(@application)
  end

  # DELETE /account/applications/:id
  def destroy
    @application.destroy
    respond_with(@application, notice: 'The application has been successfully destroyed.')
  end

  private

  def _client_application_params
    params.require(:client_application).permit(:name, :url, :callback_url, :support_url)
  end

  def _restrict_to_jilion_team
    redirect_to [:edit, :user] unless current_user.email =~ /@jilion.com$/
  end

  def _set_client_application
    @application = current_user.client_applications.find(params[:id])
  end

end
