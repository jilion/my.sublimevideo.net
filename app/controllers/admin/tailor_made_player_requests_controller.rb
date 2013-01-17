class Admin::TailorMadePlayerRequestsController < Admin::AdminController
  respond_to :html, :js

  before_filter { |controller| require_role?('god') }

  before_filter :set_default_scopes, only: [:index]
  before_filter :find_tailor_made_player_request, only: [:show, :destroy]

  # sort
  has_scope :by_topic, :by_date

  # GET /tailor_made_player_requests
  def index
    @tailor_made_player_requests = TailorMadePlayerRequest.all(params)

    respond_with(@tailor_made_player_requests)
  end

  # GET /tailor_made_player_requests/:id
  def show
  end

  # DELETE /tailor_made_player_requests/:id
  def destroy
    @tailor_made_player_request.destroy
    # Recalculate trends..., move it to wwsv once trends are out of mysv
    Stats::TailorMadePlayerRequestsStat.delay.update_stats(@tailor_made_player_request.created_at)
    respond_with @tailor_made_player_request, location: [:admin, :tailor_made_player_requests]
  end

  private

  def set_default_scopes
    params[:by_date] = 'desc' unless params.keys.any? { |k| k =~ /^by_\w+$/ }
  end

  def find_tailor_made_player_request
    @tailor_made_player_request = TailorMadePlayerRequest.find(params[:id])
  end

end
