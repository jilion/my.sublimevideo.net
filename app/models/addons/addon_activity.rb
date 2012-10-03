class Addons::AddonActivity < ActiveRecord::Base

  attr_accessible :addonship, :state

  # ================
  # = Associations =
  # ================

  belongs_to :addonship
  has_one :addon, through: :addonship

  # ===============
  # = Validations =
  # ===============

  validates :addonship_id, :state, presence: true

end

# == Schema Information
#
# Table name: addon_activities
#
#  addonship_id :integer          not null
#  created_at   :datetime         not null
#  id           :integer          not null, primary key
#  state        :string(255)      not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_addon_activities_on_addonship_id  (addonship_id)
#  index_addon_activities_on_created_at    (created_at)
#

