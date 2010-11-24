class SiteObserver < ActiveRecord::Observer
  
  def after_save(site)
    update_plans_lifetime(site)
    update_addons_lifetime(site)
  end
  
private
  
  def update_plans_lifetime(site)
    if site.plan_id_changed?
      if site.plan_id_was.present?
        set_deleted_at_to_old_lifetime(site, site.plan_id_was, "Plan")
      end
      site.lifetimes.create(:item => site.plan, :created_at => site.updated_at)
    end
  end
  
  def update_addons_lifetime(site)
    if site.addon_ids_changed?
      # Removed addon ids
      (site.addon_ids_was - site.addon_ids).each do |addon_id|
        set_deleted_at_to_old_lifetime(site, addon_id, "Addon")
      end
      # New addon ids
      (site.addon_ids - site.addon_ids_was).each do |addon_id|
        site.lifetimes.create(:item_id => addon_id, :item_type => "Addon", :created_at => site.updated_at)
      end
    end
  end
  
  def set_deleted_at_to_old_lifetime(site, item_id, item_type)
    site.lifetimes.where(:item_id => item_id, :item_type => item_type, :deleted_at => nil).first.tap do |old_lifetime|
      old_lifetime.update_attributes(:deleted_at => site.updated_at)
    end
  end
  
end