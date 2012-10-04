class Site::AddonPlan < ActiveRecord::Base
  self.table_name_prefix = 'site_'

  AVAILABILITIES = %w[hidden beta public custom]

  attr_accessible :addon, :name, :price, :availability, as: :admin

  belongs_to :addon, class_name: 'Site::Addon', foreign_key: 'site_addon_id'

  validates :addon, :name, :price, :availability, presence: true
  validates :name, uniqueness: { scope: :site_addon_id }
  validates :availability, inclusion: AVAILABILITIES
  validates :price, numericality: true
end

# == Schema Information
#
# Table name: site_addon_plans
#
#  availability  :string(255)      not null
#  created_at    :datetime         not null
#  id            :integer          not null, primary key
#  name          :string(255)      not null
#  price         :integer          not null
#  site_addon_id :integer          not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_site_addon_plans_on_site_addon_id           (site_addon_id)
#  index_site_addon_plans_on_site_addon_id_and_name  (site_addon_id,name) UNIQUE
#
