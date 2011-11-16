class Com::PagesController < ApplicationController

  def show
    params[:page] ||= 'home'
    render params[:page]
  end

end
