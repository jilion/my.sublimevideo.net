class App::Component < ActiveRecord::Base
  APP_TOKEN = 'sa'

  attr_accessible :name, :token, as: :admin

  has_many :versions, class_name: 'App::ComponentVersion', foreign_key: 'app_component_id', dependent: :destroy, order: 'version desc'
  has_many :designs, class_name: 'App::Design', foreign_key: 'app_component_id', dependent: :destroy, order: 'version desc'
  has_many :plugins, class_name: 'App::Plugin', foreign_key: 'app_component_id'

  has_many :designs_sites, through: :designs, source: :sites
  has_many :plugins_sites, through: :plugins, source: :sites

  validates :token, :name, presence: true, uniqueness: true

  after_touch :clear_caches
  after_save :clear_caches

  def self.app_component
    Rails.cache.fetch [self, 'app_component'] do
      self.where(token: APP_TOKEN).first
    end
  end

  def self.find_cached_by_name(name)
    Rails.cache.fetch [self, 'find_cached_by_name', name] do
      self.where(name: name).first
    end
  end

  class << self
    alias_method :get, :find_cached_by_name
  end

  def app_component?
    token == APP_TOKEN
  end

  def to_param
    token
  end

  def cached_versions
    Rails.cache.fetch [self, 'versions'] do
      versions.all
    end
  end

  def sites
    # via_designs = designs_sites.scoped
    # site_designs = BillableItem.app_designs.where{site_id == sites.id}
    # via_plugins = plugins_sites.where{app_plugins.app_design_id.in(site_designs.select{item_id}) | app_plugins.app_design_id.eq(nil)}
    # Site.where{ id.in(via_designs.select{id}) | id.in(via_plugins.select{id}) }

    # Query via plugins is too slow and useless for now
    designs_sites.scoped
  end

  private

  def clear_caches
    Rails.cache.clear [self.class, 'app_component']
    Rails.cache.clear [self.class, 'find_cached_by_name', name]
  end

end

# == Schema Information
#
# Table name: app_components
#
#  created_at :datetime         not null
#  id         :integer          not null, primary key
#  name       :string(255)
#  token      :string(255)
#  updated_at :datetime         not null
#
# Indexes
#
#  index_player_components_on_name   (name) UNIQUE
#  index_player_components_on_token  (token) UNIQUE
#

