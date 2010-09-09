module Admin::SitesHelper
  
  def admin_sites_page_title(sites)
    states = (params[:archived_included] ? [] : ["active"])
    states << "with activity" if params[:with_activity].present?
    "#{sites.total_entries} #{states.join(' & ')} sites".titleize
  end

end