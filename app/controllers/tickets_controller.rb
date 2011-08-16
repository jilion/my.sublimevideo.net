class TicketsController < ApplicationController
  respond_to :html

  # GET /support
  def new
    @ticket = Ticket.new
    respond_with(@ticket)
  end

  # POST /support
  def create
    @ticket = Ticket.new(params[:ticket].merge({ :user_id => current_user.id }))
    @ticket.save
    respond_with(@ticket, :location => new_ticket_url)
  end

end
