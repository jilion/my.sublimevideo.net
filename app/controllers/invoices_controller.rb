class InvoicesController < ApplicationController
  respond_to :html
  respond_to :js, :only => :usage

  def index
    redirect_to edit_user_registration_path
  end

  def usage
    @invoice = Invoice.build(site: current_user.sites.first)
    respond_with(@invoice)
  end

  def show
    @invoice = current_user.invoices.find_by_reference(params[:id])
    respond_with(@invoice)
  end

  def pay
    @invoice = current_user.invoices.failed.find_by_reference(params[:id])
    @invoice.retry
    respond_with(@invoice) do |format|
      format.html { redirect_to page_path('suspended') }
    end
  end

end
