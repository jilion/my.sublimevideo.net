module Admin::EnthusiastsHelper

  def admin_enthusiasts_page_title(enthusiasts)
    pluralized_enthusiasts = pluralize(enthusiasts.total_count, 'beta requester')
    state = if params[:search].present?
      " matching '#{params[:search]}'"
    else
      ""
    end

    "#{pluralized_enthusiasts.titleize}#{state}"
  end

end
