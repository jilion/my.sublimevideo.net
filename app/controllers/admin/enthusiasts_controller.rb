class Admin::EnthusiastsController < AdminController
  respond_to :js, :html

  has_scope :by_date
  has_scope :by_email
  has_scope :by_starred
  has_scope :by_confirmed
  has_scope :by_interested_in_beta
  has_scope :by_invited
  has_scope :with_tag
  has_scope :confirmed, type: :boolean
  has_scope :not_confirmed, type: :boolean
  has_scope :interested_in_beta, type: :boolean
  has_scope :starred, type: :boolean
  has_scope :invited, type: :boolean
  has_scope :not_invited, type: :boolean
  has_scope :search

  # GET /enthusiasts
  def index
    @enthusiasts = apply_scopes(Enthusiast.by_date('asc').confirmed(true).interested_in_beta(true))
    respond_with(@enthusiasts)
  end

  # GET /enthusiasts/1
  def show
    @enthusiast = Enthusiast.includes(:sites).find(params[:id])
    respond_with(@enthusiast)
  end

  # PUT /enthusiasts/1
  def update
    @enthusiast = Enthusiast.find(params[:id])
    @enthusiast.update_attributes(params[:enthusiast])
    respond_with(@enthusiast)
  end

end
