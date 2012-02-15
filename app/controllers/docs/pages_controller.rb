class Docs::PagesController < ApplicationController

  # caches_action :show, layout: false

  def show
    @body_class = params[:page]

    respond_to do |format|
      format.html { render "docs/pages/#{params[:page]}" }
    end
  end

end
