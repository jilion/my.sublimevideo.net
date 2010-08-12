class TicketsController < ApplicationController
  respond_to :html
  
  # GET /support
  def new
    @ticket = Ticket.new
    respond_with(@ticket)
  end
  
  # POST /support
  def create
    @ticket = Ticket.new(params[:ticket].merge({ :user => current_user }))
    if @ticket.save
      redirect_to new_ticket_url, :notice => t('ticket.submitted')
    else
      render :new
    end
  end
  
end