module Admin::UsersHelper

  def admin_users_page_title(users)
    pluralized_users = pluralize(users.total_count, 'user')
    # pluralized_users = pluralize(users.group_by(&:id).count, 'user')

    state = if params[:free]
      " free"
    elsif params[:with_state]
      " #{params[:with_state]}"
    elsif params[:search].present?
      " matching '#{params[:search]}'"
    else
      " paying"
    end
    "#{pluralized_users.titleize}#{state}"
  end

end
