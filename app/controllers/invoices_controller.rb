class InvoicesController < ApplicationController
  before_filter :redirect_suspended_user, :only => :index

  # GET /sites/:site_id/invoices
  def index
    @site = current_user.sites.find_by_token!(params[:site_id])
    @invoices = @site.invoices
    render :index, :layout => 'application'
  end

  # GET /invoices/:id
  def show
    @invoice = current_user.invoices.find_by_reference!(params[:id])
    respond_with(@invoice)
  end

  # PUT /invoices/:site_id/retry
  def retry
    @site = current_user.sites.find_by_token!(params[:site_id])
    @invoices = @site.invoices.failed

    if @invoices.present?
      Transaction.charge_by_invoice_ids(@invoices.map(&:id))
      transaction = @site.last_invoice.last_transaction
      if transaction.paid?
        flash[:notice] = t("site.invoices.retry_succeed")
      else
        flash[:alert] = t("transaction.errors.#{transaction.i18n_error_key}")
      end
    else
      flash[:notice] = t("site.invoices.no_failed_invoices_to_retry")
    end

    respond_to do |format|
      format.html { redirect_to site_invoices_url(site_id: @site.token) }
    end
  end

end
