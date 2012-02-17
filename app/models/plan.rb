class Plan < ActiveRecord::Base
  include PlanModules::Api

  CYCLES                = %w[month year none]
  UNPAID_NAMES          = %w[free sponsored]
  STANDARD_NAMES        = %w[plus premium]
  SUPPORT_LEVELS        = %w[forum email vip_email]

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
  validate :price_is_present_and_numeric

  def price_is_present_and_numeric
    errors.add(:price, "must be present.") if read_attribute(:price).nil?
  end

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
      create(attributes.merge(name: "custom - #{attributes[:name]}"))
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
    if site && deal = site.user.latest_activated_deal
      if (site.trial_started_at? && site.trial_started_at >= deal.started_at && site.trial_started_at <= deal.ended_at) || deal.active?
        return deal if %W[plans_discount #{cycle}ly_plans_discount #{name}_plan_discount].include?(deal.kind)
      end
    end

    nil
  end

  def discounted_percentage(site=nil)
    if deal = discounted?(site)
      deal.value
    else
      0
    end
  end

  def price(site=nil)
    read_attribute(:price) * (1 - discounted_percentage(site))
  end

end
# == Schema Information
#
# Table name: plans
#
#  id                   :integer         not null, primary key
#  name                 :string(255)
#  token                :string(255)
#  cycle                :string(255)
#  video_views          :integer
#  price                :integer
#  created_at           :datetime
#  updated_at           :datetime
#  support_level        :integer         default(0)
#  stats_retention_days :integer
#
# Indexes
#
#  index_plans_on_name_and_cycle  (name,cycle) UNIQUE
#  index_plans_on_token           (token) UNIQUE
#
