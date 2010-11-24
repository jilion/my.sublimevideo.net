class Lifetime < ActiveRecord::Base
  
  # ================
  # = Associations =
  # ================
  belongs_to :site
  belongs_to :item, :polymorphic => true
  
  # ==========
  # = Scopes =
  # ==========
  
  scope :alive_between, lambda { |started_at, ended_at| where({ :created_at.lte => ended_at }, { :deleted_at => nil } | { :deleted_at.gte => started_at }) }
  
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

