class My::TicketsController < MyController
  respond_to :html

  # POST /support
  def create
    @ticket = Ticket.new(params[:ticket].merge({ user_id: current_user.id }))
    @ticket.save
    respond_with(@ticket, location: page_url('help'))
  end

end
