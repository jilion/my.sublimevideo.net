class Version < ActiveRecord::Base
  attr_accessible :admin_id, :ip # for paper_trail, overwritten
end
# == Schema Information
#
# Table name: versions
#
#  id         :integer         not null, primary key
#  item_type  :string(255)     not null
#  item_id    :integer         not null
#  event      :string(255)     not null
#  whodunnit  :string(255)
#  object     :text
#  created_at :datetime
#  admin_id   :string(255)
#  ip         :string(255)
#  user_agent :string(255)
#
# Indexes
#
#  index_versions_on_item_type_and_item_id  (item_type,item_id)
#

