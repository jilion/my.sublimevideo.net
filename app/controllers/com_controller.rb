class ComController < ApplicationController
  before_filter :cache_page

  def show
    render params[:page]
  end

end