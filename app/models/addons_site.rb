class AddonsSite < ActiveRecord::Base
end

# == Schema Information
#
# Table name: addons_sites
#
#  site_id    :integer
#  addon_id   :integer
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_addons_sites_on_addon_id  (addon_id)
#  index_addons_sites_on_site_id   (site_id)
#

