class Site::Kit < ActiveRecord::Base
  self.table_name_prefix = 'site_'

  attr_accessible :site, :design, as: :admin
  attr_accessible :name

  belongs_to :site
  belongs_to :design, class_name: 'App::Design', foreign_key: 'app_design_id'

  validates :site, :design, :name, presence: true
  validates :name, uniqueness: { scope: :site_id }
end

# == Schema Information
#
# Table name: site_kits
#
#  app_design_id :integer          not null
#  created_at    :datetime         not null
#  id            :integer          not null, primary key
#  name          :string(255)      default("Default"), not null
#  settings      :hstore
#  site_id       :integer          not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_site_kits_on_app_design_id     (app_design_id)
#  index_site_kits_on_site_id           (site_id)
#  index_site_kits_on_site_id_and_name  (site_id,name) UNIQUE
#
