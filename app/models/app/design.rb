require 'findable_and_cached'

class App::Design < ActiveRecord::Base
  include FindableAndCached

  AVAILABILITIES = %w[public custom]

  attr_accessible :component, :skin_token, :name, :price, :availability, :required_stage, :stable_at, as: :admin

  belongs_to :component, class_name: 'App::Component', foreign_key: 'app_component_id'
  has_many :billable_items, as: :item
  has_many :sites, through: :billable_items

  validates :component, :skin_token, :name, :price, :availability, :required_stage, presence: true
  validates :price, numericality: true
  validates :availability, inclusion: AVAILABILITIES
  validates :required_stage, inclusion: Stage.stages

  after_save :clear_caches

  scope :beta,   -> { where(stable_at: nil) }
  scope :custom, -> { where { availability == 'custom' } }
  scope :paid,   -> { where { price > 0 } }

  def available_for_subscription?(site)
    case availability
    when 'public'
      true
    when 'custom'
      site.app_designs.where(id: id).exists?
    end
  end

  def not_custom?
    availability == 'public'
  end

  def beta?
    !stable_at?
  end

  def free?
    price.zero?
  end

  def title
    I18n.t("app_designs.#{name}")
  end
  
  def free_plan
    nil
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

