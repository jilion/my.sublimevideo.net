class InvoicesController < ApplicationController
  before_filter :redirect_suspended_user, :only => :index

  # GET /sites/:site_id/invoices
  def index
    @site = current_user.sites.find_by_token(params[:site_id])
    @invoices = @site.invoices
    render :index, :layout => 'application'
  end

  # GET /invoices/:id
  def show
    @invoice = current_user.invoices.find_by_reference(params[:id])
    respond_with(@invoice)
  end

  # PUT /invoices/:id/pay
  def pay
    @invoice = current_user.invoices.failed.find_by_reference(params[:id])
    @invoice.retry
    redirect_to page_path('suspended')
  end

end
