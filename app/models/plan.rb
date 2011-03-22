class Plan < ActiveRecord::Base

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

  scope :free_plans,     where(:name => ["dev", "beta", "sponsored"])
  scope :paid_plans,     where(:name.not_in => ["dev", "beta", "sponsored"])
  scope :standard_plans, where(:name.in => STANDARD_NAMES)
  scope :custom_plans,   where(:name.matches => "custom%")

  # =================
  # = Class Methods =
  # =================

  def self.dev_plan
    where(:name => "dev").first
  end

  def self.beta_plan
    where(:name => "beta").first
  end

  def self.sponsored_plan
    where(:name => "sponsored").first
  end

  def self.create_custom(attributes)
    name = "custom#{custom_plans.count + 1}"
    create(attributes.merge(:name => name))
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
    Plan.where(:price.gt => price).order(:price).first
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

  def dev_plan?
    name == "dev"
  end

  def beta_plan?
    name == "beta"
  end

  def sponsored_plan?
    name == "sponsored"
  end

  def standard_plan?
    STANDARD_NAMES.include?(name)
  end

  def custom_plan?
    name =~ /^custom.*/
  end

  def paid_plan?
    !dev_plan? && !beta_plan? && !sponsored_plan?
  end

  CYCLES.each do |c|
    define_method("#{c}ly?") do
      cycle == c
    end
  end

  def title(options = {})
    if dev_plan?
      "Free Sandbox"
    elsif sponsored_plan?
      "Sponsored"
    elsif options[:always_with_cycle]
      name.titleize + (cycle == 'year' ? ' (yearly)' : ' (monthly)')
    else
      name.titleize + (cycle == 'year' ? ' (yearly)' : '')
    end
  end

  def daily_player_hits
    player_hits / 30
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
#

