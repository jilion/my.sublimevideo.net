class Lifetime < ActiveRecord::Base
  
  # ================
  # = Associations =
  # ================
  belongs_to :site
  belongs_to :item, :polymorphic => true
  
  def self.addons_minutes_uptime(user, year, month)
    month_start = Time.utc(year, month).beginning_of_month
    month_end   = Time.utc(year, month).end_of_month
    
    results = []
    where({ :site_id => user.sites },
          { :created_at.lte => month_end },
          { :deleted_at => nil } | { :deleted_at => month_start..month_end }).each do |lifetime|
      started_at = ([lifetime.created_at, month_start].max).change(:usec => 0)
      ended_at   = (lifetime.deleted_at || month_end).change(:usec => 0)
      
      results << { :type => "site",
                   :site_id => lifetime.site.id,
                   :addon_id => lifetime.item_id,
                   :started_at => started_at,
                   :ended_at => ended_at,
                   :minutes => seconds_to_minutes(ended_at - started_at)
                 }
    end
    results
  end
  
  def self.seconds_to_minutes(seconds)
    (seconds / 60.0).ceil
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

