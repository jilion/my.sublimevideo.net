class InvoicesController < ApplicationController

  before_filter :redirect_suspended_user, only: [:index]
  before_filter :_set_sites_or_redirect_to_new_site, only: [:index]
  before_filter :_set_site, only: [:index]

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

end
