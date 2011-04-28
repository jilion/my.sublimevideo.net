module Admin::UsersHelper

  def admin_users_page_title(users)
    pluralized_users = pluralize(users.total_count, 'user')

    state = if params.keys.all? { |k| k =~ /^by_/ || %w[action controller search].include?(k) }
      " active & billable"
    elsif params[:active_and_not_billable]
      " active & not billable"
    elsif params[:with_state]
      " with #{params[:with_state]} state"
    elsif params[:search].present?
      " that contains '#{params[:search]}'"
    else
      ""
    end
    "#{pluralized_users.titleize}#{state}"
  end

end
