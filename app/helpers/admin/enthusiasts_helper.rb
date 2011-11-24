module Admin::EnthusiastsHelper

  def admin_enthusiasts_page_title(enthusiasts)
    state = if params[:confirmed] == false
      "unconfirmed"
    # elsif params[:confirmed] == true
    #   "confirmed"
    # elsif params[:interested_in_beta].present?
    #   "interested in beta"
    elsif params[:starred].present?
      "starred"
    else
      "confirmed & interested in beta"
    end
    "#{enthusiasts.total_count} #{state} enthusiasts".titleize
  end

end
