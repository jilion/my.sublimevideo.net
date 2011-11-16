class Docs::ReleasesController < ApplicationController
  respond_to :atom

  layout 'my_application'

  def index
    @releases = Docs::Release.all.reverse

    respond_with(@releases)
  end

end
