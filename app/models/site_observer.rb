class SiteObserver < ActiveRecord::Observer

  def after_save(site)
    update_plans_lifetime(site)
  end

private

  def update_plans_lifetime(site)
    if site.plan_id_changed?
      if site.plan_id_was.present?
        set_deleted_at_to_old_lifetime(site, site.plan_id_was, "Plan")
      end
      site.lifetimes.create(:item => site.plan, :created_at => Time.now.utc)
    end
  end

  def set_deleted_at_to_old_lifetime(site, item_id, item_type)
    site.lifetimes.where(:item_id => item_id, :item_type => item_type, :deleted_at => nil).first.tap do |old_lifetime|
      old_lifetime.update_attributes(:deleted_at => Time.now.utc)
    end
  end

end
