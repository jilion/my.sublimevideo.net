module Admin::EnthusiastsHelper

  def admin_enthusiasts_page_title(enthusiasts)
    state = if params[:confirmed] == false
      "unconfirmed"
    elsif params[:confirmed] == true
      "confirmed"
    elsif params[:interested_in_beta].present?
      "interested in beta"
    elsif params[:starred].present?
      "starred"
    else
      ""
    end
    "#{enthusiasts.total_entries} #{state} enthusiasts".titleize
  end

  def existing_tags_for(resource)
    Tag.select("DISTINCT(name)").joins(:taggings).where("taggings.taggable_type = '#{resource.to_s.classify}'").map(&:name).join(", ")
  end

end
