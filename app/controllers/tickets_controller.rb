class TicketsController < ApplicationController
  respond_to :html

  before_filter :redirect_user_with_no_email_support

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

private

  def redirect_user_with_no_email_support
    redirect_to "http://sublimevideo.net/help" if current_user.support == 'forum'
  end

end
