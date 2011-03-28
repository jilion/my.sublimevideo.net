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
    create(attributes.merge(:name => "custom#{custom_plans.count + 1}"))
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

  # free plan
  def beta_plan?
    name == "beta"
  end

  # free plan
  def dev_plan?
    name == "dev"
  end

  # free plan
  def sponsored_plan?
    name == "sponsored"
  end

  def free_plan?
    beta_plan? || dev_plan? || sponsored_plan?
  end

  # paid plan
  def standard_plan?
    STANDARD_NAMES.include?(name.gsub(/\d/, ''))
  end

  # paid plan
  def custom_plan?
    name =~ /^custom.*/
  end

  def paid_plan?
    !free_plan?
  end

  CYCLES.each do |c|
    define_method("#{c}ly?") do
      cycle == c
    end
  end

  def title(options = {})
    if dev_plan?
      "Free LaunchPad"
    elsif sponsored_plan?
      "Sponsored"
    elsif custom_plan?
      "Custom"
    elsif options[:always_with_cycle]
      name.titleize + (cycle == 'year' ? ' (yearly)' : ' (monthly)')
    else
      name.titleize + (cycle == 'year' ? ' (yearly)' : '')
    end
  end

  def daily_player_hits
    player_hits / 30
  end

  def support
    if STANDARD_NAMES[-2,2].include?(name) || custom_plan? || sponsored_plan?
      "priority"
    else
      "standard"
    end
  end

  def price(site=nil, refund=false)
    if site && site.user.beta? &&
      ((!site.first_paid_plan_started_at? && Time.now.utc < PublicLaunch.beta_transition_ended_on) ||
        refund && (site.first_paid_plan_started_at? && site.first_paid_plan_started_at < PublicLaunch.beta_transition_ended_on && site.invoices.count < 2)) # deduct the first discount only for the first upgrade
      if self.yearly?
        (read_attribute(:price) * 0.8 / 100).to_i * 100
      else
        (read_attribute(:price) * 0.8 / 10).to_i * 10
      end
    else
      read_attribute(:price)
    end
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

