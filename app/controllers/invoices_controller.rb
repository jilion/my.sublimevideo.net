class InvoicesController < ApplicationController
  before_filter :authenticate_user!
  respond_to :html, :except => :show
  respond_to :js
  
  # GET /invoices
  def index
    @invoices = current_user.invoices.by_charged_at
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