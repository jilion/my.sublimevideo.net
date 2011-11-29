class Docs::ReleasesController < ApplicationController
  respond_to :atom

  before_filter :cache_page, if: proc { |c| request.format == :atom }

  def index
    @releases = Docs::Release.all.reverse

    respond_with(@releases)
  end

end
