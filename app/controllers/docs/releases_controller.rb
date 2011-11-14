class Docs::ReleasesController < DocsController
  respond_to :html, :atom

  def index
    @releases = Docs::Release.all.reverse
    params[:page] = "releases"

    respond_with(@releases)
  end

end
