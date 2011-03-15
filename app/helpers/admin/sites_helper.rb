module Admin::SitesHelper

  def admin_sites_page_title(sites)
    states = (params[:archived_included] ? [] : ["active"])
    states << "with activity" if params[:with_activity].present?
    states << "with activity in last 30 days" if params[:with_activity_in_last_30_days].present?
    "#{sites.total_entries} #{states.join(' & ')} sites".titleize
  end

end