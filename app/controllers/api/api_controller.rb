class Api::ApiController < ApplicationController
  respond_to :xml
  
  skip_before_filter :authenticate_user!
  before_filter :authenticate_api!
  
private
  
  def authenticate_api!
    unless request.headers["TOKEN"] == (ENV['API_TOKEN'] || "MGq3Y4PcPQ9nr8G6xuVF")
      render :nothing => true, :status => :unauthorized
    end
  end
  
end