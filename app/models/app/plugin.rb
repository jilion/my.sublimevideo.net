require 'findable_and_cached'

class App::Plugin < ActiveRecord::Base
  include FindableAndCached

  belongs_to :addon
  belongs_to :design
  belongs_to :component, class_name: 'App::Component', foreign_key: 'app_component_id'
  has_many :sites, through: :addon

  after_save :clear_caches

  validates :addon, :component, presence: true
  validates :addon_id, uniqueness: { scope: :design_id }
end

# == Schema Information
#
# Table name: app_plugins
#
#  addon_id         :integer          not null
#  app_component_id :integer          not null
#  created_at       :datetime
#  design_id        :integer
#  id               :integer          not null, primary key
#  mod              :string(255)
#  name             :string(255)      not null
#  token            :string(255)      not null
#  updated_at       :datetime
#
# Indexes
#
#  index_app_plugins_on_design_id               (design_id)
#  index_app_plugins_on_design_id_and_addon_id  (design_id,addon_id)
#

