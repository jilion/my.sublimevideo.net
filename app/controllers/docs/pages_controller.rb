class Docs::PagesController < ApplicationController
  layout 'my_application'

  before_filter :cache_page

  def show
    render "docs/pages/#{params[:page]}"
  end

end
