class InvoicesController < ApplicationController
  respond_to :html
  respond_to :js, :only => :usage
  
  before_filter :find_by_reference, :only => [:show, :pay]
  
  def usage
    @invoice = Invoice.usage_statement(current_user)
    respond_with(@invoice)
  end
  
  def show
    respond_with(@invoice)
  end
  
  def pay
    Invoice.charge(@invoice.id)
    respond_with(@invoice) do |format|
      format.html { redirect_to page_path('suspended') }
    end
  end
  
private
  
  def find_by_reference
    @invoice = current_user.invoices.find_by_reference(params[:id])
  end
  
end