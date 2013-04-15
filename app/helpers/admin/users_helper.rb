module Admin::UsersHelper

  def admin_users_page_title(users)
    state = if params[:free]
      ' free'
    elsif params[:paying]
      ' paying'
    elsif params[:with_balance]
      ' with a balance'
    elsif params[:with_state]
      " #{params[:with_state]}"
    elsif params[:tagged_with]
      " tagged with '#{params[:tagged_with]}'"
    elsif params[:sites_tagged_with]
      " with site(s) tagged with '#{params[:sites_tagged_with]}'"
    elsif params[:search]
      " matching '#{params[:search]}'"
    end

    "#{formatted_pluralize(users.total_count, 'user').titleize}#{state}"
  end

end
