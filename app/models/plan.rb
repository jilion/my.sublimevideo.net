class Plan < ActiveRecord::Base
  CYCLES         = %w[month year none]
  UNPAID_NAMES   = %w[trial free sponsored]
  STANDARD_NAMES = %w[plus premium]
  SUPPORT_LEVELS = %w[forum email vip_email]

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

  class << self
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
    end
  end

  # ====================
  # = Instance Methods =
  # ====================

  # unpaid plan
  UNPAID_NAMES.each do |plan_name|
    define_method "#{plan_name}_plan?" do
      name == plan_name
    end
  end

  CYCLES.each do |cycle_name|
    define_method "#{cycle_name}ly?" do
      cycle == cycle_name
    end
  end

  def title(options = {})
    "#{name.gsub(/\d/, '').titleize.strip} Plan" + (cycle == 'year' ? ' (yearly)' : '')
  end

end

# == Schema Information
#
# Table name: plans
#
#  created_at           :datetime
#  cycle                :string(255)
#  id                   :integer          not null, primary key
#  name                 :string(255)
#  price                :integer
#  stats_retention_days :integer
#  support_level        :integer          default(0)
#  token                :string(255)
#  updated_at           :datetime
#  video_views          :integer
#
# Indexes
#
#  index_plans_on_name_and_cycle  (name,cycle) UNIQUE
#  index_plans_on_token           (token) UNIQUE
#

