class My::TicketsController < MyController
  respond_to :html

  # POST /support
  def create
    @ticket = Ticket.new(params[:ticket].merge({ user_id: current_user.id }))
    respond_with(@ticket) do |format|
      if @ticket.save
        format.html { redirect_to page_path('help'), notice: I18n.t('flash.tickets.create.notice') }
      else
        format.html { render 'my/pages/help' }
      end
    end
  end

end
