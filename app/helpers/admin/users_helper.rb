module Admin::UsersHelper

  def admin_users_page_title(users)
    pluralized_users = pluralize(users.total_entries, 'user')
    
    state = if params.keys.all? { |k| k =~ /^by_/ || %w[action controller search].include?(k) }
      " active & billable"
    elsif params[:active_and_not_billable]
      " active & not billable"
    elsif params[:will_be_suspended]
      " will be suspended"
    elsif params[:with_state]
      " with #{params[:with_state]} state"
    else
      ""
    end
    "#{pluralized_users.titleize}#{state.humanize}"
  end

  def link_to_user(user)
    if user.invited?
      link_to user.email, admin_user_path(user)
    else
      link_to user.full_name, admin_user_path(user), :title => "#{user.full_name} <#{user.email}>"
    end
  end

end
