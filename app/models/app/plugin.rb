class App::Plugin < ActiveRecord::Base
  serialize :condition, Hash

  attr_accessible :addon, :design, :component, :token, :name, as: :admin

  belongs_to :addon
  belongs_to :design, class_name: 'App::Design', foreign_key: 'app_design_id'
  belongs_to :component, class_name: 'App::Component', foreign_key: 'app_component_id'
  has_many :sites, through: :addon

  after_save :clear_caches

  validates :addon, :component, presence: true
  validates :addon_id, uniqueness: { scope: :app_design_id }

  def self.find_cached_by_name(name)
    Rails.cache.fetch [self, 'find_cached_by_name', name] do
      self.where(name: name.to_s).first
    end
  end

  class << self
    alias_method :get, :find_cached_by_name
  end

  private

  def clear_caches
    Rails.cache.clear [self.class, 'find_cached_by_name', name]
  end

end

# == Schema Information
#
# Table name: app_plugins
#
#  addon_id         :integer          not null
#  app_component_id :integer          not null
#  app_design_id    :integer
#  condition        :text
#  created_at       :datetime         not null
#  id               :integer          not null, primary key
#  name             :string(255)      not null
#  token            :string(255)      not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_app_plugins_on_app_design_id               (app_design_id)
#  index_app_plugins_on_app_design_id_and_addon_id  (app_design_id,addon_id)
#

