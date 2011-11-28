class Docs::PagesController < ApplicationController

  def show
    render "docs/pages/#{params[:page]}"
  end

end
