class InvoicesController < ApplicationController
  include InvoicesControllerHelper

  before_filter :redirect_suspended_user, only: [:index]
  before_filter :_set_sites_or_redirect_to_new_site, only: [:index]
  before_filter :_set_site, only: [:index, :retry]

  layout 'application' # needed because otherwise the 'invoices' layout is automatically used

  # GET /sites/:site_id/invoices
  def index
    @invoices = @site.invoices.not_canceled.by_date

    respond_with(@invoices)
  end

  # GET /invoices/:id
  def show
    @invoice = current_user.invoices.not_canceled.where(reference: params[:id]).first!

    respond_with(@invoice, layout: 'invoices')
  end

  # PUT /invoices/:site_id/retry
  def retry
    @invoices = @site.invoices.open_or_failed

    _retry_invoices(@invoices)

    respond_with(@invoices) do |format|
      format.html { redirect_to site_invoices_url(site_id: @site.to_param) }
    end
  end

  # PUT /invoices/retry_all
  def retry_all
    @invoices = current_user.invoices.open_or_failed

    _retry_invoices(@invoices)

    respond_with(@invoices) do |format|
      format.html { redirect_to sites_url }
    end
  end

end
