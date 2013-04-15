class BillableEntity < ActiveRecord::Base
  self.abstract_class = true
  AVAILABILITIES = %w[hidden public custom]

  attr_accessible :name, :price, :availability, :required_stage, :stable_at, as: :admin

  has_many :billable_items, as: :item
  has_many :sites, through: :billable_items

  #
  # Scopes defined on abstract class simply don't work when called from a subclass...
  #
  def self.free
    where(price: 0)
  end

  def self.paid
    where { (stable_at != nil) & (price > 0) }
  end

  def self.custom
    where(availability: 'custom')
  end

  def self.not_custom
    where(availability: %w[hidden public])
  end

  def self.visible
    where { availability != 'hidden' }
  end

  validates :price, numericality: true
  validates :availability, inclusion: AVAILABILITIES
  validates :required_stage, inclusion: Stage.stages

  def free?
    price.zero?
  end

  def not_custom?
    availability.in?(%w[hidden public])
  end

  def beta?
    stable_at.nil?
  end

  def available_for_subscription?(site)
    raise NotImplementedError, "This #{self.class} cannot respond to: #{__method__}"
  end

  def title
    raise NotImplementedError, "This #{self.class} cannot respond to: #{__method__}"
  end

  def free_plan
    raise NotImplementedError, "This #{self.class} cannot respond to: #{__method__}"
  end
end
