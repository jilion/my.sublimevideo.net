class Www::PagesController < ApplicationController

  # caches_action :show, layout: false

  def show
    params[:page] ||= 'home'
    if params[:p] && user_signed_in?
      redirect_to sites_url(subdomain: 'my')
    else
      @body_class = params[:page]
      render params[:page]
    end
  end

end
