module Admin::EnthusiastsHelper

  def admin_enthusiasts_page_title(enthusiasts)
    formatted_pluralize(enthusiasts.total_count, 'beta requester').titleize
  end

end
