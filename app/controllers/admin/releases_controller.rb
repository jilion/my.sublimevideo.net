class Admin::ReleasesController < Admin::AdminController
  respond_to :html
  respond_to :js, :only => :index
  
  before_filter :allow_only_zeno
  
  # GET /admin/releases
  def index
    @releases = Release.order(:date.desc)
    respond_with(@releases)
  end
  
  # POST /admin/releases
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
  
  # PUT /admin/releases/:id
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
    unless Rails.env.development?
      redirect_to '/admin' unless current_admin.email == "zeno@jilion.com"
    end
  end
  
end