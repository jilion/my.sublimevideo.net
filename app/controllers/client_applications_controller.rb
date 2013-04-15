class ClientApplicationsController < ApplicationController
  before_filter :team_accessible_only
  before_filter :get_client_application, only: [:show, :edit, :update, :destroy]

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
    @application = current_user.client_applications.build(params[:client_application])
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
    @application.update_attributes(params[:client_application])
    respond_with(@application)
  end

  # DELETE /account/applications/:id
  def destroy
    @application.destroy
    respond_with(@application, notice: 'The application has been successfully destroyed.')
  end

  private

  def team_accessible_only
    redirect_to [:edit, :user] unless current_user.email =~ /@jilion.com$/
  end

  def get_client_application
    unless @application = current_user.client_applications.find(params[:id])
      flash.now[:error] = 'Wrong application id'
      raise ActiveRecord::RecordNotFound
    end
  end

end
