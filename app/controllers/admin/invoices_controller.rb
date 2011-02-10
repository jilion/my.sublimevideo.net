class Admin::InvoicesController < Admin::AdminController
  respond_to :js, :html

  before_filter :compute_date_range, :only => :edit

  # filter
  has_scope :paid
  has_scope :failed
  has_scope :user_id
  # sort
  has_scope :by_user
  has_scope :by_date, :default_way
  # has_scope :by_sites_count
  has_scope :by_invoice_items_count
  has_scope :by_amount
  has_scope :by_state
  has_scope :by_attempts
  # search
  has_scope :search

  # GET /admin/invoices
  def index
    @invoices = Invoice.includes(:user)
    @invoices = apply_scopes(@invoices)
    @invoices.by_date unless params[:by_invoice_items_count]
    respond_with(@invoices)
  end

  # GET /admin/invoices/:id
  def show
    @invoice = Invoice.includes(:user).find_by_reference(params[:id])
    respond_with(@invoice) do |format|
      format.html { render :template => '/invoices/show', :layout => 'invoices' }
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

  # PUT /admin/invoices/:id/cancel_charging
  def cancel_charging
    @invoice = Invoice.find_by_reference(params[:id])
    Invoice.transaction do
      @invoice.charging_delayed_job.destroy
      @invoice.update_attribute(:charging_delayed_job_id, nil)
    end
    respond_with(@invoice, :location => [:admin, :invoices])
  end
end
