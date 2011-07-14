class OauthClientsController < ApplicationController
  before_filter :get_client_application, :only => [:show, :edit, :update, :destroy]

  def index
    @client_applications = current_user.client_applications
    @authorizations = current_user.tokens.where({ :invalidated_at => nil } & { :authorized_at.ne => nil })
  end

  def new
    @client_application = ClientApplication.new
  end

  def create
    @client_application = current_user.client_applications.build(params[:client_application])
    respond_with(@client_application) do |format|
      if @client_application.save
        format.html { redirect_to :show, :id => @client_application.id, :notice => "Registered the information successfully" }
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
    @client_application.update_attributes(params[:client_application])
    respond_with(@client_application)
    # respond_with(@client_application) do |format|
    #   if @client_application.update_attributes(params[:client_application])
    #     format.html { redirect_to :show, :id => @client_application.id, :notice => "Updated the client information successfully" }
    #   else
    #     format.html { render :edit }
    #   end
    # end
  end

  def destroy
    @client_application.destroy
    respond_with(@client_application)
    # redirect_to :action => "index", :notice => "Destroyed the client application registration"
  end

  private
  
  def get_client_application
    unless @client_application = current_user.client_applications.find(params[:id])
      flash.now[:error] = "Wrong application id"
      raise ActiveRecord::RecordNotFound
    end
  end
  
end
