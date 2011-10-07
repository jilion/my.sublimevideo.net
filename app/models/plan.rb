class Plan < ActiveRecord::Base
  include PlanModules::Api

  CYCLES         = %w[month year none]
  UNPAID_NAMES = %w[free sponsored]
  LEGACY_UNPAID_NAMES = %w[dev]
  STANDARD_NAMES = %w[silver gold]
  LEGACY_STANDARD_NAMES = %w[comet planet star galaxy]
  SUPPORT_LEVELS = %w[forum email]

  attr_accessible :name, :cycle, :video_views, :price, :support_level
  uniquify :token, :chars => Array('a'..'z') + Array('0'..'9'), :length => 12

  # ================
  # = Associations =
  # ================

  has_many :sites
  has_many :invoice_items, :as => :item

  # ===============
  # = Validations =
  # ===============

  validates :name,          :presence => true, :uniqueness => { :scope => :cycle }
  validates :video_views,   :presence => true, :numericality => true
  validates :price,         :presence => true, :numericality => true
  validates :cycle,         :presence => true, :inclusion => CYCLES
  validates :support_level, :presence => true, :inclusion => (0...SUPPORT_LEVELS.size)

  # ==========
  # = Scopes =
  # ==========

  scope :unpaid_plans,   where { name >> ["free", "sponsored"] }
  scope :paid_plans,     where { name << ["free", "sponsored"] }
  scope :standard_plans, where { name >> STANDARD_NAMES }
  scope :custom_plans,   where { name =~ "custom%" }

  # =================
  # = Class Methods =
  # =================

  class << self
    extend ActiveSupport::Memoizable

    def create_custom(attributes)
      create(attributes.merge(:name => "custom - #{attributes[:name]}"))
    end

    %w[free sponsored].each do |plan_name|
      method_name = "#{plan_name}_plan"
      define_method(method_name) do
        where(name: plan_name).first
      end
      memoize method_name.to_sym
    end

    STANDARD_NAMES.each do |plan_name|
      method_name = "#{plan_name}_video_views"
      define_method(method_name) do
        where(name: plan_name).first.video_views
      end
      memoize method_name.to_sym

      method_name = "#{plan_name}_daily_video_views"
      define_method(method_name) do
        where(name: plan_name).first.daily_video_views
      end
      memoize method_name.to_sym
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
    Plan.where { price > my{price} }.order(:price.asc).first
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
  (UNPAID_NAMES + LEGACY_UNPAID_NAMES).each do |plan_name|
    define_method "#{plan_name}_plan?" do
      name == plan_name
    end
  end

  # paid plan
  def standard_plan?
    (STANDARD_NAMES + LEGACY_STANDARD_NAMES).include?(name.gsub(/\d/, ''))
  end

  # paid plan
  def custom_plan?
    name =~ /^custom.*/
  end

  def unpaid_plan?
    free_plan? || sponsored_plan?
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
    if free_plan?
      "Free"
    elsif sponsored_plan?
      "Sponsored"
    elsif options[:always_with_cycle]
      name.gsub(/\d/, '').titleize + (cycle == 'year' ? ' (yearly)' : ' (monthly)')
    else
      name.gsub(/\d/, '').titleize + (cycle == 'year' ? ' (yearly)' : '')
    end
  end

  def daily_video_views
    video_views / 30
  end

  def support
    SUPPORT_LEVELS[support_level]
  end

  def discounted?(site)
    false
  end

  def discounted_percentage
    0.2
  end

end



# == Schema Information
#
# Table name: plans
#
#  id            :integer         not null, primary key
#  name          :string(255)
#  token         :string(255)
#  cycle         :string(255)
#  video_views   :integer
#  price         :integer
#  created_at    :datetime
#  updated_at    :datetime
#  support_level :integer         default(0)
#
# Indexes
#
#  index_plans_on_name_and_cycle  (name,cycle) UNIQUE
#  index_plans_on_token           (token) UNIQUE
#

