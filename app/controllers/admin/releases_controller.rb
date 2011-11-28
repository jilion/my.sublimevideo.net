class Admin::ReleasesController < AdminController
  respond_to :html
  respond_to :js, only: :index

  before_filter :allow_only_zeno

  # GET /releases
  def index
    @releases = Release.order(:date.desc)
    respond_with(@releases)
  end

  # POST /releases
  def create
    @release = Release.new(params[:release])
    respond_with(@release) do |format|
      if @release.save
        format.html { redirect_to [:admin, :releases] }
      else
        format.html { render :index }
      end
    end
  end

  # PUT /releases/:id
  def update
    @release = Release.find(params[:id])
    respond_with(@release) do |format|
      if @release.flag
        format.html { redirect_to [:admin, :releases] }
      else
        format.html { render :index }
      end
    end
  end

private

  def allow_only_zeno
    redirect_to '/admin' unless zeno?
  end

end
