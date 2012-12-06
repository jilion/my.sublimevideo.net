class Admin::TailorMadePlayerRequestsController < Admin::AdminController
  respond_to :html, :js

  before_filter { |controller| require_role?('god') }

  before_filter :set_default_scopes, only: [:index]
  before_filter :find_tailor_made_player_request, only: [:show]

  # sort
  has_scope :by_topic, :by_date

  def index
    @tailor_made_player_requests = apply_scopes(TailorMadePlayerRequest.scoped)

    respond_with(@tailor_made_player_requests, per_page: 50)
  end

  def show
  end

  private

  def set_default_scopes
    params[:by_date] = 'desc' unless params.keys.any? { |k| k =~ /^by_\w+$/ }
  end

  def find_tailor_made_player_request
    @tailor_made_player_request = TailorMadePlayerRequest.find(params[:id])
  end

end
