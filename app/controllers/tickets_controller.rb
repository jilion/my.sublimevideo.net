class TicketsController < ApplicationController
  respond_to :html
  
  # GET /support
  def new
    @ticket = Ticket.new
    respond_with(@ticket)
  end
  
  # POST /support
  def create
    @ticket = Ticket.new(current_user, params[:ticket])
    if @ticket.save
      flash[:notice] = "Your message has been submitted."
      redirect_to new_ticket_url
    else
      render :new
    end
  end
  
end