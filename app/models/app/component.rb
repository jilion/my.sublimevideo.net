require 'findable_and_cached'

class App::Component < ActiveRecord::Base
  include FindableAndCached

  APP_TOKEN = 'sa'

  has_many :versions, -> { order(created_at: :desc) }, class_name: 'App::ComponentVersion', foreign_key: 'app_component_id', dependent: :destroy
  has_many :designs, -> { order(created_at: :desc) }, class_name: 'Design', foreign_key: 'app_component_id', dependent: :destroy
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

  def app_component?
    token == APP_TOKEN
  end

  def to_param
    token
  end

  def versions_for_stage(stage)
    _cached_versions.select { |v| Stage.stages_equal_or_more_stable_than(stage).include?(v.stage) }
  end

  def sites
    # via_designs = designs_sites.all
    # site_designs = BillableItem.designs.where { site_id == sites.id }
    # via_plugins = plugins_sites.where {app_plugins.design_id.in(site_designs.select{item_id}) | app_plugins.design_id.eq(nil)}
    # Site.where { id.in(via_designs.select{id}) | id.in(via_plugins.select{id}) }

    # Query via plugins is too slow and useless for now
    designs_sites
  end

  def clear_caches
    super
    Rails.cache.clear [self.class, 'app_component']
    Rails.cache.clear [self, 'versions']
  end

  private

  def _cached_versions
    Rails.cache.fetch [self, 'versions'] { versions }
  end

end

# == Schema Information
#
# Table name: app_components
#
#  created_at :datetime
#  id         :integer          not null, primary key
#  name       :string(255)
#  token      :string(255)
#  updated_at :datetime
#
# Indexes
#
#  index_app_components_on_name   (name) UNIQUE
#  index_app_components_on_token  (token) UNIQUE
#

