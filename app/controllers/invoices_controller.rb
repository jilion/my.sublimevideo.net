class InvoicesController < ApplicationController
  respond_to :html
  respond_to :js, :only => :usage
  
  before_filter :redirect_suspended_user
  
  def usage
    @invoice = Invoice.usage_statement(current_user)
    respond_with(@invoice)
  end
  
  def show
    @invoice = current_user.invoices.find_by_reference(params[:id])
    respond_with(@invoice)
  end
  
end