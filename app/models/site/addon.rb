class Site::Addon < ActiveRecord::Base
  self.table_name_prefix = 'site_'

  attr_accessible :name, :design_dependent, as: :admin

  validates :name, :design_dependent, presence: true
  validates :name, uniqueness: true
end

# == Schema Information
#
# Table name: site_addons
#
#  created_at       :datetime         not null
#  design_dependent :boolean          not null
#  id               :integer          not null, primary key
#  name             :string(255)      not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_site_addons_on_name  (name) UNIQUE
#
