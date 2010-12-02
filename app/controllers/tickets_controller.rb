class TicketsController < ApplicationController
  respond_to :html
  
  before_filter :redirect_suspended_user
  
  # GET /support
  def new
    @ticket = Ticket.new
    respond_with(@ticket)
  end
  
  # POST /support
  def create
    @ticket = Ticket.new(params[:ticket].merge({ :user => current_user }))
    @ticket.save
    respond_with(@ticket, :location => new_ticket_url)
  end
  
end