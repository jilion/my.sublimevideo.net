class SiteVersion < PaperTrail::Version
  self.table_name    = :versions
  self.sequence_name = :version_id_seq

  attr_accessible :admin_id, :ip # for paper_trail, overwritten
end

# == Schema Information
#
# Table name: versions
#
#  admin_id   :string(255)
#  created_at :datetime
#  event      :string(255)      not null
#  id         :integer          not null, primary key
#  ip         :string(255)
#  item_id    :integer          not null
#  item_type  :string(255)      not null
#  object     :text
#  user_agent :string(255)
#  whodunnit  :string(255)
#
# Indexes
#
#  index_versions_on_item_type_and_item_id  (item_type,item_id)
#

