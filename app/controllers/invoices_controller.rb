class InvoicesController < ApplicationController
  respond_to :html
  
  before_filter :redirect_suspended_user
  before_filter :find_by_token, :only => [:show]
  
  def show
    respond_with(@invoice)
  end
  
  def current
    respond_with(@invoice = Invoice.build(:user => current_user, :started_at => Time.now.utc.beginning_of_month, :ended_at => Time.now.utc.end_of_month))
  end
  
private
  
  def find_by_token
    @invoice = current_user.invoices.find_by_token(params[:id])
  end
  
end