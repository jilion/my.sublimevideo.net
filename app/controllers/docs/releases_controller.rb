class Docs::ReleasesController < ApplicationController
  respond_to :atom

  before_filter :cache_page

  def index
    @releases = Docs::Release.all.reverse

    respond_with(@releases)
  end

end
