class InvoicesController < ApplicationController
  before_filter :authenticate_user!
  
  # GET /invoices
  def index
    Invoice.current(current_user)
    @invoices = current_user.invoices
    respond_with(@invoices)
  end
  
  # GET /invoices/1 || /invoices/current
  def show
    @invoice = if params[:id] == 'current'
      Invoice.current(current_user)
    else
      current_user.invoices.find(params[:id])
    end
    respond_with(@invoice)
  end
  
end
