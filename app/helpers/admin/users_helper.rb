module Admin::UsersHelper
  
  def admin_users_page_title(users)
    state = if params[:enthusiast].present?
      "enthusiast"
    elsif params[:beta].present?
      "in beta"
    # elsif params[:with_activity].present?
    #   "with activity"
    else
      ""
    end
    "#{users.total_entries} #{state} users".titleize
  end
  
  def link_to_user(user)
    if user.invited?
      link_to user.email, admin_user_path(user)
    else
      link_to user.full_name, admin_user_path(user), :title => "#{user.full_name} <#{user.email}>"
    end
  end
  
end