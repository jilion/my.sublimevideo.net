class PagesController < ApplicationController
  skip_before_filter :authenticate_user!, if: proc { |c| %w[terms privacy help].include?(params[:page]) }
  before_filter :redirect_non_suspended_user!, if: proc { |c| params[:page] == 'suspended' && user_signed_in? && !current_user.suspended? }
  before_filter :prepare_ticket, if: proc { |c| params[:page] == 'help' && user_signed_in? && current_user.email_support? }
  before_filter :redirect_to_public_help, if: proc { |c| params[:page] == 'help' && !user_signed_in? }

  def show
    render params[:page]
  end

private

  def redirect_non_suspended_user!
    redirect_to root_path
  end

  def redirect_to_public_help
    redirect_to "http://#{request.domain}/help"
  end

  def prepare_ticket
    @ticket = Ticket.new
  end

end
