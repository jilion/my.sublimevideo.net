require_dependency 'hostname'

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
#  created_at    :datetime
#  enthusiast_id :integer
#  hostname      :string(255)
#  id            :integer          not null, primary key
#  updated_at    :datetime
#
# Indexes
#
#  index_enthusiast_sites_on_enthusiast_id  (enthusiast_id)
#

