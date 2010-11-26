class InvoicesController < ApplicationController
  respond_to :html
  
  before_filter :redirect_suspended_user
  
  def usage
    @invoice = Invoice.build(
      :user => current_user,
      :started_at => Time.now.utc.beginning_of_month,
      :ended_at => Time.now.utc
    )
    respond_with(@invoice)
  end
  
  def show
    @invoice = current_user.invoices.find_by_reference(params[:id])
    respond_with(@invoice)
  end
  
end