class InvoicesController < ApplicationController
  before_filter :redirect_suspended_user, :only => :index

  # GET /sites/:site_id/invoices
  def index
    @sites    = current_user.sites.not_archived.with_not_canceled_invoices
    @site     = current_user.sites.not_archived.find_by_token!(params[:site_id])
    @invoices = @site.invoices.not_canceled.by_date

    render :index, layout: 'application'
  end

  # GET /invoices/:id
  def show
    @invoice = current_user.invoices.not_canceled.find_by_reference!(params[:id])

    respond_with(@invoice)
  end

  # PUT /invoices/:site_id/retry
  def retry
    @site     = current_user.sites.not_archived.find_by_token!(params[:site_id])
    @invoices = @site.invoices.open_or_failed

    if @invoices.present?
      transaction = Transaction.charge_by_invoice_ids(@invoices.map(&:id))
      if transaction.paid?
        flash[:notice] = t("site.invoices.retry_succeed")
      else
        flash[:alert] = t("transaction.errors.#{transaction.state}")
      end
    else
      flash[:notice] = t("site.invoices.no_invoices_to_retry")
    end

    respond_with(@invoices) do |format|
      format.html { redirect_to site_invoices_url(site_id: @site.to_param) }
    end
  end

  # PUT /invoices/retry_all
  def retry_all
    @invoices = current_user.invoices.open_or_failed

    if @invoices.present?
      transaction = Transaction.charge_by_invoice_ids(@invoices.map(&:id))
      if transaction.paid?
        flash[:notice] = t("site.invoices.retry_succeed")
      else
        flash[:alert] = t("transaction.errors.#{transaction.state}")
      end
    else
      flash[:notice] = t("site.invoices.no_invoices_to_retry")
    end

    respond_with(@invoices) do |format|
      format.html { redirect_to sites_url }
    end
  end

end
