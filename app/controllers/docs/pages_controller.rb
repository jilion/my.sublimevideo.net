class Docs::PagesController < ApplicationController

  before_filter :cache_page
  
  def show
    render "docs/pages/#{params[:page]}"
  end

end
