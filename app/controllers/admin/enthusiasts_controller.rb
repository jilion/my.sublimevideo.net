class Admin::EnthusiastsController < Admin::AdminController
  respond_to :js, :html

  has_scope :by_date, :by_email, :by_starred, :by_confirmed, :by_interested_in_beta, :by_invited
  has_scope :confirmed, :not_confirmed, :interested_in_beta, :starred, :invited, :not_invited, type: :boolean
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
