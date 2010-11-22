class Lifetime < ActiveRecord::Base
  
  def self.addons_minutes_uptime(user, year, month)
    { 
      :site_id => [
        { :addon_id =>, :started_at => , :ended_at => , :minutes => }
      ]
    }
    
    
  end
  
end

# == Schema Information
#
# Table name: lifetimes
#
#  id         :integer         not null, primary key
#  site_id    :integer
#  item_type  :string(255)
#  item_id    :integer
#  created_at :datetime
#  deleted_at :datetime
#
# Indexes
#
#  index_lifetimes_created_at  (site_id,item_type,item_id,created_at)
#  index_lifetimes_deleted_at  (site_id,item_type,item_id,deleted_at) UNIQUE
#

