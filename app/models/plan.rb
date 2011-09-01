class Plan < ActiveRecord::Base
  include Plan::Api

  CYCLES         = %w[month year none]
  STANDARD_NAMES = %w[comet planet star galaxy]

  attr_accessible :name, :cycle, :player_hits, :price
  uniquify :token, :chars => Array('a'..'z') + Array('0'..'9'), :length => 12

  # ================
  # = Associations =
  # ================

  has_many :sites
  has_many :invoice_items, :as => :item

  # ===============
  # = Validations =
  # ===============

  validates :name,        :presence => true, :uniqueness => { :scope => :cycle }
  validates :player_hits, :presence => true, :numericality => true
  validates :price,       :presence => true, :numericality => true
  validates :cycle,       :presence => true, :inclusion => { :in => CYCLES }

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

    def free_plan
      where(name: "free").first
    end
    memoize :free_plan

    def sponsored_plan
      where(name: "sponsored").first
    end
    memoize :sponsored_plan

    def create_custom(attributes)
      create(attributes.merge(name: "custom#{custom_plans.count + 1}"))
    end

    STANDARD_NAMES.each do |name|
      name_method = "#{name}_player_hits"
      define_method(name_method) do
        where(name: name).first.player_hits
      end
      memoize name_method.to_sym
    end

    STANDARD_NAMES.each do |name|
      name_method = "#{name}_daily_player_hits"
      define_method(name_method) do
        where(name: name).first.daily_player_hits
      end
      memoize name_method.to_sym
    end

  end

  # ====================
  # = Instance Methods =
  # ====================

  def upgrade?(new_plan)
    if yearly? && new_plan.monthly?
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
  def free_plan?
    name == "free"
  end

  # unpaid plan
  def sponsored_plan?
    name == "sponsored"
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

  CYCLES.each do |c|
    define_method("#{c}ly?") do
      cycle == c
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

  def daily_player_hits
    player_hits / 30
  end

  def support
    if STANDARD_NAMES[-2,2].include?(name) || custom_plan? || sponsored_plan?
      "priority"
    elsif free_plan?
      "launchpad"
    else
      "standard"
    end
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
#  id          :integer         not null, primary key
#  name        :string(255)
#  token       :string(255)
#  cycle       :string(255)
#  player_hits :integer
#  price       :integer
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_plans_on_name_and_cycle  (name,cycle) UNIQUE
#  index_plans_on_token           (token) UNIQUE
#

