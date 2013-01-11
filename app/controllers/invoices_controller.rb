class InvoicesController < ApplicationController
  before_filter :redirect_suspended_user, only: [:index]
  before_filter :find_sites_or_redirect_to_new_site, only: [:index]
  before_filter :find_site_by_token!, only: [:index, :retry]

  layout 'application' # needed because otherwise the 'invoices' layout is automatically used

  # GET /sites/:site_id/invoices
  def index
    @invoices = @site.invoices.not_canceled.by_date

    respond_with(@invoices)
  end

  # GET /invoices/:id
  def show
    @invoice = current_user.invoices.not_canceled.find_by_reference!(params[:id])

    respond_with(@invoice, layout: 'invoices')
  end

  # PUT /invoices/:site_id/retry
  def retry
    @invoices = @site.invoices.open_or_failed

    retry_invoices(@invoices)

    respond_with(@invoices) do |format|
      format.html { redirect_to site_invoices_url(site_id: @site.to_param) }
    end
  end

  # PUT /invoices/retry_all
  def retry_all
    @invoices = current_user.invoices.open_or_failed

    retry_invoices(@invoices)

    respond_with(@invoices) do |format|
      format.html { redirect_to sites_url }
    end
  end

  private

  def retry_invoices(invoices)
    if invoices.present?
      transaction = Transaction.charge_by_invoice_ids(invoices.map(&:id))
      if transaction.paid?
        flash[:notice] = t('invoice.retry_succeed')
      else
        flash[:alert] = t("transaction.errors.#{transaction.state}")
      end
    else
      flash[:notice] = t('invoice.no_invoices_to_retry')
    end
  end

end
