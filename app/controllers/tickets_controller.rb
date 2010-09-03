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
    respond_with(@user) do |format|
      if @ticket.save
        format.html { redirect_to new_ticket_url }
      else
        format.html { render :new }
      end
    end
  end
  
end