class Admin::ReleasesController < Admin::AdminController
  respond_to :html
  respond_to :js, only: :index

  before_filter { |controller| require_role?('player') }

  # GET /releases
  def index
    @releases = Release.order(:date.desc)
    respond_with(@releases)
  end

  # POST /releases
  def create
    @release = Release.new(params[:release])
    @release.save!
    respond_with(@release) do |format|
      format.html { redirect_to [:admin, :releases] }
    end
  end

  # PUT /releases/:id
  def update
    @release = Release.find(params[:id])
    @release.flag!
    respond_with(@release) do |format|
      format.html { redirect_to [:admin, :releases] }
    end
  end

end
