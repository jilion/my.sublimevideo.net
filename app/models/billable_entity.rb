require 'stage'

module BillableEntity
  extend ActiveSupport::Concern

  included do
    has_many :billable_items, as: :item
    has_many :sites, through: :billable_items

    scope :beta,    -> { where(stable_at: nil) }
    scope :paid,    -> { where{ (stable_at != nil) & (price > 0) } }
    scope :custom,  -> { where{ availability == 'custom' } }
    scope :visible, -> { where{ availability != 'hidden' } }
    scope :public,  -> { where{ availability >> %w[hidden public] } }

    validates :price, numericality: true
    validates :availability, inclusion: availabilities
    validates :required_stage, inclusion: Stage.stages
  end

  module ClassMethods
    def availabilities
      %w[hidden public custom]
    end
  end

  def not_custom?
    availability.in?(%w[hidden public])
  end

  def beta?
    stable_at.nil?
  end

  def free?
    price.zero?
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
