module Admin::UsersHelper
  
  def admin_users_page_title(users)
    state = if params[:enthusiast].present?
      "enthusiast"
    elsif params[:beta].present?
      "in beta"
    elsif params[:with_activity].present?
      "with activity"
    else
      ""
    end
    "#{users.total_entries} #{state} users".titleize
  end

end