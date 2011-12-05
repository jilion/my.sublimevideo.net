class Docs::PagesController < ApplicationController

  # caches_action :show, layout: false

  def show
    render "docs/pages/#{params[:page]}"
  end

end
