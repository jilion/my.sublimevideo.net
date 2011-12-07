class Docs::PagesController < ApplicationController

  # caches_action :show, layout: false

  def show
    @body_class = params[:page]
    render "docs/pages/#{params[:page]}"
  end

end
