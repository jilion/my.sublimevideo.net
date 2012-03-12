class EnthusiastSite < ActiveRecord::Base

  attr_accessible :hostname

  # ================
  # = Associations =
  # ================

  belongs_to :enthusiast

  # ===============
  # = Validations =
  # ===============

  validates :hostname, presence: true, hostname: true

  # ====================
  # = Instance Methods =
  # ====================
  # add scheme & parse
  def hostname=(attribute)
    write_attribute(:hostname, Hostname.clean(attribute))
  end

end
# == Schema Information
#
# Table name: enthusiast_sites
#
#  id            :integer         not null, primary key
#  enthusiast_id :integer
#  hostname      :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#
# Indexes
#
#  index_enthusiast_sites_on_enthusiast_id  (enthusiast_id)
#

