module Admin::UsersHelper
  
  def admin_users_page_title(users)
    pluralized_users = pluralize(users.total_entries, 'user')
    state = if params[:will_be_suspended]
      " will be suspended"
    elsif params[:use_personal]
      " with personal usage"
    elsif params[:use_company]
      " with company usage"
    elsif params[:use_clients]
      " with client usage"
    else
      ""
    end
    "#{pluralized_users}#{state}".titleize
  end
  
  def link_to_user(user)
    if user.invited?
      link_to user.email, admin_user_path(user)
    else
      link_to user.full_name, admin_user_path(user), :title => "#{user.full_name} <#{user.email}>"
    end
  end
  
end