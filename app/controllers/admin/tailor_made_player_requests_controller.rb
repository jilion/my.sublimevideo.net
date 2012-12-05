require_dependency 'service/tailor_made_player_request'

class Admin::TailorMadePlayerRequestsController < Admin::AdminController
  respond_to :html, :js

  before_filter :set_default_scopes, only: [:index]
  before_filter :find_tailor_made_player_request, only: [:show, :export_to_highrise]

  # sort
  has_scope :by_topic, :by_date

  def index
    @tailor_made_player_requests = apply_scopes(TailorMadePlayerRequest.scoped)

    respond_with(@tailor_made_player_requests, per_page: 50)
  end

  def show
  end

  def export_to_highrise
    service = Service::TailorMadePlayerRequest.new(@tailor_made_player_request)

    case params[:tailor_made_player_request][:export_type]
    when 'person'
      success = service.export_person_to_highrise
      @notice = "The person & company #{success ? 'have been successfully' : 'haven\'t been'} imported into Highrise."
    when 'company'
      success = service.export_company_to_highrise
      @notice = "The company #{success ? 'has been successfully' : 'hasn\'t been'} imported into Highrise."
    when 'kase'
      success = service.create_case_in_highrise
      @notice = "The case #{success ? 'has been successfully' : 'hasn\'t been'} created in Highrise."
    end

    redirect_to [:admin, @tailor_made_player_request], notice: @notice
  end

  private

  def set_default_scopes
    params[:by_date] = 'desc' unless params.keys.any? { |k| k =~ /^by_\w+$/ }
  end

  def find_tailor_made_player_request
    @tailor_made_player_request = TailorMadePlayerRequest.find(params[:id])
  end

end
