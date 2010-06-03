class PagesController < ApplicationController
 
  def show
    render params[:page]
  end
  
end
