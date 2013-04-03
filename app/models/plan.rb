class Plan < ActiveRecord::Base

  CYCLES         = %w[month year none]
  UNPAID_NAMES   = %w[trial free sponsored]
  STANDARD_NAMES = %w[plus premium]
  SUPPORT_LEVELS = %w[forum email vip_email]

  attr_accessible :name, :cycle, :video_views, :price, :support_level, :stats_retention_days
  uniquify :token, chars: Array('a'..'z') + Array('0'..'9'), length: 12

  # ================
  # = Associations =
  # ================

  has_many :sites
  has_many :invoice_items, as: :item

  # ===============
  # = Validations =
  # ===============

  validates :name,          presence: true, uniqueness: { scope: :cycle }
  validates :video_views,   presence: true, numericality: true
  validates :cycle,         presence: true, inclusion: CYCLES
  validates :support_level, presence: true, inclusion: (0...SUPPORT_LEVELS.size)
  validate  :price_is_present # needed since we redefine the price accessor

  def price_is_present
    errors.add(:price, 'must be present.') if read_attribute(:price).nil?
  end

  # ==========
  # = Scopes =
  # ==========

  scope :unpaid_plans,   -> { where{ name >> UNPAID_NAMES } }
  scope :paid_plans,     -> { where{ name << UNPAID_NAMES } }
  scope :standard_plans, -> { where{ name >> STANDARD_NAMES } }
  scope :custom_plans,   -> { where{ name =~ 'custom%' } }
  scope :yearly_plans,   -> { where{ cycle == 'year' } }

  # =================
  # = Class Methods =
  # =================

  class << self
    def create_custom(attributes)
      create(attributes.merge(name: "custom - #{attributes[:name]}"))
    end

    UNPAID_NAMES.each do |plan_name|
      method_name = "#{plan_name}_plan"
      define_method(method_name) do
        where(name: plan_name).first
      end
    end

    STANDARD_NAMES.each do |plan_name|
      method_name = "#{plan_name}_video_views"
      define_method(method_name) do
        where(name: plan_name).first.video_views
      end

      method_name = "#{plan_name}_daily_video_views"
      define_method(method_name) do
        where(name: plan_name).first.daily_video_views
      end
    end
  end

  # ====================
  # = Instance Methods =
  # ====================

  def upgrade?(new_plan)
    if new_plan.nil? || (yearly? && new_plan.monthly?)
      false
    elsif self == new_plan
      nil
    else
      month_price(10) <= new_plan.month_price(10)
    end
  end

  def next_plan
    Plan.where{ price > my{price} }.order{ price.asc }.first
  end

  def month_price(months = 12)
    case cycle
    when "month"
      price
    when "year"
      price / months
    else
      0
    end
  end

  # unpaid plan
  UNPAID_NAMES.each do |plan_name|
    define_method "#{plan_name}_plan?" do
      name == plan_name
    end
  end

  # paid plan
  def standard_plan?
    STANDARD_NAMES.include?(name.gsub(/\d/, ''))
  end

  # paid plan
  def custom_plan?
    name =~ /^custom.*/
  end

  def unpaid_plan?
    price.zero?
  end

  def paid_plan?
    !unpaid_plan?
  end

  CYCLES.each do |cycle_name|
    define_method "#{cycle_name}ly?" do
      cycle == cycle_name
    end
  end

  def title(options = {})
    "#{name.gsub(/\d/, '').titleize.strip} Plan" + (cycle == 'year' ? ' (yearly)' : '')
  end

  def daily_video_views
    video_views / 30
  end

  def support
    SUPPORT_LEVELS[support_level]
  end

  def discounted_percentage(site=nil)
    0
  end

  def price(site = nil)
    read_attribute(:price) * (1 - discounted_percentage(site))
  end

  def free?
    price.zero?
  end

  def beta?
    false
  end

end

# == Schema Information
#
# Table name: plans
#
#  created_at           :datetime         not null
#  cycle                :string(255)
#  id                   :integer          not null, primary key
#  name                 :string(255)
#  price                :integer
#  stats_retention_days :integer
#  support_level        :integer          default(0)
#  token                :string(255)
#  updated_at           :datetime         not null
#  video_views          :integer
#
# Indexes
#
#  index_plans_on_name_and_cycle  (name,cycle) UNIQUE
#  index_plans_on_token           (token) UNIQUE
#

