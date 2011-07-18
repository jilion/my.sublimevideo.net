class OauthClientsController < ApplicationController
  before_filter :get_client_application, :only => [:show, :edit, :update, :destroy]

  def index
    @applications = current_user.client_applications
    @authorizations = current_user.tokens.where({ :invalidated_at => nil } & { :authorized_at.ne => nil })
  end

  def new
    @application = ClientApplication.new
  end

  def create
    @application = current_user.client_applications.build(params[:client_application])
    respond_with(@application) do |format|
      if @application.save
        format.html { redirect_to application_url(@application), id: @application.id, notice: "Application registered successfully." }
      else
        format.html { render :new }
      end
    end
  end

  def show
  end

  def edit
  end

  # PUT /applications/:id
  def update
    @application.update_attributes(params[:client_application])
    respond_with(@application)
  end

  def destroy
    @application.destroy
    respond_with(@application)
  end

  private
  
  def get_client_application
    unless @application = current_user.client_applications.find(params[:id])
      flash.now[:error] = "Wrong application id"
      raise ActiveRecord::RecordNotFound
    end
  end
  
end
