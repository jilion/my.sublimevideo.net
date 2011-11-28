class Www::PagesController < ApplicationController

  before_filter :cache_page

  def show
    params[:page] ||= 'home'
    render params[:page]
  end

end
