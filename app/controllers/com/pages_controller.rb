class Com::PagesController < ApplicationController

  before_filter :cache_page

  def show
    params[:page] ||= 'home'
    if params[:p] && user_signed_in?
      redirect_to sites_url(subdomain: 'my')
    else
      render params[:page]
    end
  end

end
