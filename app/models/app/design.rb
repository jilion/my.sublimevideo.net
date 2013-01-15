require_dependency 'stage'

class App::Design < ActiveRecord::Base
  AVAILABILITIES = %w[public custom] unless defined? AVAILABILITIES

  attr_accessible :component, :skin_token, :name, :price, :availability, :required_stage, :stable_at, as: :admin

  belongs_to :component, class_name: 'App::Component', foreign_key: 'app_component_id'
  has_many :billable_items, as: :item
  has_many :sites, through: :billable_items

  validates :component, :skin_token, :name, :price, :availability, :required_stage, presence: true
  validates :price, numericality: true
  validates :availability, inclusion: AVAILABILITIES
  validates :required_stage, inclusion: Stage.stages

  after_save :clear_caches

  scope :custom, -> { where { availability == 'custom' } }
  scope :paid,   -> { where { price > 0 } }

  def self.find_cached_by_name(name)
    Rails.cache.fetch [self, 'find_cached_by_name', name.to_s.dup] do
      self.where(name: name.to_s).first
    end
  end

  class << self
    alias_method :get, :find_cached_by_name
  end

  def available_for_subscription?(site)
    case availability
    when 'public'
      true
    when 'custom'
      site.app_designs.where(id: id).exists?
    end
  end

  def public?
    availability == 'public'
  end

  def beta?
    !stable_at?
  end

  def free?
    beta? || price.zero?
  end

  def title
    I18n.t("app_designs.#{name}")
  end

  private

  def clear_caches
    Rails.cache.clear [self.class, 'find_cached_by_name', name]
  end
end

# == Schema Information
#
# Table name: app_designs
#
#  app_component_id :integer          not null
#  availability     :string(255)      not null
#  created_at       :datetime         not null
#  id               :integer          not null, primary key
#  name             :string(255)      not null
#  price            :integer          not null
#  required_stage   :string(255)      default("stable"), not null
#  skin_token       :string(255)      not null
#  stable_at        :datetime
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_app_designs_on_name        (name) UNIQUE
#  index_app_designs_on_skin_token  (skin_token) UNIQUE
#

