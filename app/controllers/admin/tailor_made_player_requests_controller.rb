class Admin::TailorMadePlayerRequestsController < Admin::AdminController
  respond_to :html, :js

  before_filter { |controller| require_role?('god') }

  before_filter :_set_default_scopes, only: [:index]
  before_filter :_set_tailor_made_player_request, only: [:show, :destroy]

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
    # Recalculate trends..., move it to wwsv once trends are out of mysv
    TailorMadePlayerRequestsTrend.delay(queue: 'my', at: 1.minute.from_now.to_i).update_trends(@tailor_made_player_request.created_at)
    @tailor_made_player_request.destroy
    respond_with @tailor_made_player_request, location: [:admin, :tailor_made_player_requests]
  end

  private

  def _set_default_scopes
    params[:by_date] = 'desc' unless params.keys.any? { |k| k =~ /^by_\w+$/ }
  end

  def _set_tailor_made_player_request
    @tailor_made_player_request = TailorMadePlayerRequest.find(params[:id])
  end

end
