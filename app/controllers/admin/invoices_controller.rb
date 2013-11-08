class Admin::InvoicesController < Admin::AdminController
  include InvoicesControllerHelper

  respond_to :js, :html, :json
  respond_to :json, only: [:index]

  before_filter { |controller| require_role?('invoices') }
  before_filter :_set_dates, only: [:monthly, :yearly, :top_customers]

  # filter
  has_scope :paid, type: :boolean
  has_scope :paid_between, using: [:started_at, :ended_at]
  has_scope :with_state, :user_id, :site_id, :by_id, :by_date, :by_amount, :by_user, :search

  # GET /invoices
  def index
    @invoices = apply_scopes(Invoice.not_canceled.includes(:site, :user, :transactions)).by_date
    respond_with(@invoices, per_page: 50) do |format|
      format.json { render json: @invoices.to_json(include: [:site, :user]) }
    end
  end

  # GET /invoices/:id
  def show
    redirect_to edit_admin_invoice_path(params[:id])
  end

  # GET /invoices/:id/edit
  def edit
    @invoice = Invoice.includes(:user).where(reference: params[:id]).first!

    respond_with(@invoice)
  end

  # GET /invoices/:id/edit
  def edit
    @invoice = Invoice.includes(:user).where(reference: params[:id]).first!
    respond_with(@invoice)
  end

  # PATCH /invoices/:id/retry_charging
  def retry_charging
    @invoice = Invoice.where(reference: params[:id]).first!
    _retry_invoices([@invoice])

    respond_with(@invoice, location: [:edit, :admin, @invoice])
  end

  def monthly
    @to = Time.now.utc.end_of_month
  end

  def yearly
  end

  def top_customers
  end

  private

  def _set_dates
    @from = Time.utc(2011, 3)
    @to   = Time.now.utc.end_of_year
  end

end
