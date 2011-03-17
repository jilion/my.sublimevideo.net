class Plan < ActiveRecord::Base

  CYCLES = %w[month year none]

  attr_accessible :name, :cycle, :player_hits, :price

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

  scope :free_plans, where(:name => ["dev", "beta"])
  scope :paid_plans, where(:name.not_in => ["dev", "beta"])

  # =================
  # = Class Methods =
  # =================

  def self.dev_plan
    where(:name => "dev").first
  end

  def self.beta_plan
    where(:name => "beta").first
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

  def paid_plan?
    !dev_plan? && !beta_plan?
  end

  CYCLES.each do |c|
    define_method("#{c}ly?") do
      cycle == c
    end
  end

  def title
    name.titleize + (cycle == 'year' ? ' (yearly)' : '')
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

