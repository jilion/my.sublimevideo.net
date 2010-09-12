class TicketsController < ApplicationController
  respond_to :html
  
  # GET /feedback
  def new
    @ticket = Ticket.new
    respond_with(@ticket)
  end
  
  # POST /feedback
  def create
    @ticket = Ticket.new(params[:ticket].merge({ :user => current_user }))
    respond_to do |format|
      if @ticket.save
        format.html { redirect_to new_ticket_url, :notice => "Your message has been submitted." }
      else
        format.html { render :new }
      end
    end
  end
  
end