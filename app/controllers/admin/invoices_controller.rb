class Admin::InvoicesController < Admin::AdminController
  respond_to :js, :html

  # filter
  has_scope :paid
  has_scope :open do |controller, scope|
    scope.open
  end
  has_scope :waiting
  has_scope :refunded
  has_scope :failed
  has_scope :user_id
  has_scope :site_id
  # sort
  has_scope :by_date
  has_scope :by_amount
  has_scope :by_user
  has_scope :by_invoice_items_count
  # search
  has_scope :search

  # GET /admin/invoices
  def index
    @invoices = apply_scopes(Invoice.includes(:site, :user)).by_id
    respond_with(@invoices, :per_page => 50)
  end

  # GET /admin/invoices/:id
  def show
    @invoice = Invoice.includes(:user).find_by_reference(params[:id])
    respond_with(@invoice) do |format|
      if @invoice
        format.html { render :template => '/invoices/show', :layout => 'invoices' }
      else
        format.html { redirect_to [:admin, :invoices], :notice => "Invoice with reference ##{params[:id]} not found." }
      end
    end
  end

  # GET /admin/invoices/:id/edit
  def edit
    @invoice = Invoice.includes(:user).find_by_reference(params[:id])
    respond_with(@invoice)
  end

  # PUT /admin/invoices/:id/retry_charging
  def retry_charging
    @invoice = Invoice.find_by_reference(params[:id])
    @invoice.retry
    respond_with(@invoice, :location => [:admin, :invoices])
  end

  def monthly

  end

end
