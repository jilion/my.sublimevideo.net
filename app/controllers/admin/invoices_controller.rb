class Admin::InvoicesController < AdminController
  respond_to :js, :html, :json
  respond_to :json, only: [:index]

  before_filter { |controller| require_role?('invoices') }

  # filter
  has_scope :paid
  has_scope :paid_between, using: [:started_at, :ended_at]
  has_scope :open do |controller, scope|
    scope.open
  end
  has_scope :waiting
  has_scope :refunded
  has_scope :failed
  has_scope :renew
  has_scope :user_id
  has_scope :site_id
  # sort
  has_scope :by_date
  has_scope :by_amount
  has_scope :by_user
  has_scope :by_invoice_items_count
  # search
  has_scope :search

  # GET /invoices
  def index
    @invoices = apply_scopes(Invoice.includes(:site, :user)).by_id
    respond_with(@invoices, per_page: 50) do |format|
      format.json { render json: @invoices.to_json(include: [:site, :user]) }
    end
  end

  # GET /invoices/:id
  def show
    @invoice = Invoice.includes(:user).find_by_reference(params[:id])
    respond_with(@invoice) do |format|
      if @invoice
        format.html { render template: '/my/invoices/show', layout: 'invoices' }
      else
        format.html { redirect_to [:admin, :invoices], notice: "Invoice with reference ##{params[:id]} not found." }
      end
    end
  end

  # GET /invoices/:id/edit
  def edit
    @invoice = Invoice.includes(:user).find_by_reference(params[:id])
    respond_with(@invoice)
  end

  # PUT /invoices/:id/retry_charging
  def retry_charging
    @invoice = Invoice.find_by_reference(params[:id])
    @invoice.retry
    respond_with(@invoice, location: [:admin, :invoices])
  end

  def monthly
  end

end
