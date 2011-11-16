class Docs::ReleasesController < ApplicationController
  respond_to :atom

  def index
    @releases = Docs::Release.all.reverse

    respond_with(@releases)
  end

end
