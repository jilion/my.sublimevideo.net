class Docs::PagesController < ApplicationController
  layout 'my_application'

  def show
    render "docs/pages/#{params[:page]}"
  end

end
