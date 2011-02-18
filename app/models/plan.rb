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

  validates :name,        :presence => true, :uniqueness => true
  validates :player_hits, :presence => true, :numericality => true
  validates :price,       :presence => true, :numericality => true
  validates :cycle,       :presence => true, :inclusion => { :in => CYCLES }

  # ====================
  # = Instance Methods =
  # ====================

  def next_plan
    Plan.where(:price.gt => price).order(:price).first
  end

  def month_price
    case cycle
    when "month"
      price
    when "year"
      price / 12
    end
  end

  def dev_plan?
    name == "dev"
  end

  def beta_plan?
    name == "beta"
  end

  # =================
  # = Class Methods =
  # =================

  def self.dev_plan
    where(:name => "dev").first
  end

  def self.beta_plan
    where(:name => "beta").first
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
#  index_plans_on_name  (name) UNIQUE
#

