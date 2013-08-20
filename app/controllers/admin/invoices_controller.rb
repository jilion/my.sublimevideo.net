class Admin::InvoicesController < Admin::AdminController
  respond_to :js, :html, :json
  respond_to :json, only: [:index]

  before_filter { |controller| require_role?('invoices') }
  before_filter :_set_dates, only: [:monthly, :yearly, :top_customers]

  # filter
  has_scope :paid, type: :boolean
  has_scope :paid_between, using: [:started_at, :ended_at]
  has_scope :with_state, :renew, :user_id, :site_id, :by_id, :by_date, :by_amount, :by_user, :search

  # GET /invoices
  def index
    @invoices = apply_scopes(Invoice.not_canceled.includes(:site, :user, :transactions)).by_date
    respond_with(@invoices, per_page: 50) do |format|
      format.json { render json: @invoices.to_json(include: [:site, :user]) }
    end
  end

  # GET /invoices/:id
  def show
    @invoice = Invoice.includes(:user).where(reference: params[:id]).first!
    respond_with(@invoice) do |format|
      if @invoice
        format.html { render template: '/invoices/show', layout: 'invoices' }
      else
        format.html { redirect_to [:admin, :invoices], notice: "Invoice with reference ##{params[:id]} not found." }
      end
    end
  end

  # GET /invoices/:id/edit
  def edit
    @invoice = Invoice.includes(:user).where(reference: params[:id]).first!
    respond_with(@invoice)
  end

  # PUT /invoices/:id/retry_charging
  def retry_charging
    @invoice = Invoice.where(reference: params[:id]).first!
    @invoice.retry
    respond_with(@invoice, location: [:admin, :invoices])
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
