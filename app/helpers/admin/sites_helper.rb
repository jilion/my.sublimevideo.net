module Admin::SitesHelper
  
  def admin_sites_page_title(sites)
    state = if params[:with_activity].present?
      "with activity"
    else
      ""
    end
    "#{sites.total_entries} #{state} sites".titleize
  end

end