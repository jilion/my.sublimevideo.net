class Admin::EnthusiastsController < Admin::AdminController
  respond_to :js, :html

  has_scope :by_email, :by_created_at, :by_invited_at
  has_scope :search

  # GET /enthusiasts
  def index
    @enthusiasts = apply_scopes(Enthusiast.includes(:sites, :user))
    respond_with(@enthusiasts)
  end

  # GET /enthusiasts/1
  def show
    @enthusiast = Enthusiast.includes(:sites).find(params[:id])
    respond_with(@enthusiast)
  end

end
