class DealActivation < ActiveRecord::Base

  attr_accessible :deal_id, :user_id

  # ================
  # = Associations =
  # ================

  belongs_to :deal
  belongs_to :user

  # ===============
  # = Validations =
  # ===============

  validates :deal_id, presence: true, uniqueness: { scope: :user_id }
  validates :user_id, presence: true

  # ==========
  # = Scopes =
  # ==========

  scope :active, lambda { includes(:deal).merge(Deal.active) }

  # =============
  # = Callbacks =
  # =============

  before_validation :ensure_available_to_user, if: :deal_id?
  before_validation :ensure_deal_is_active, if: :deal_id?
  before_validation :set_activated_at

private

  # before_validation
  def ensure_deal_is_active
    unless deal.active?
      self.errors.add(:base, "This deal is not active.")
    end
  end

  # before_validation
  def ensure_available_to_user
    unless deal.available_to?(user)
      self.errors.add(:base, "You can't activate this deal.")
    end
  end

  # before_validation
  def set_activated_at
    self.activated_at ||= Time.now.utc
  end

end

# == Schema Information
#
# Table name: deal_activations
#
#  activated_at :datetime
#  created_at   :datetime         not null
#  deal_id      :integer
#  id           :integer          not null, primary key
#  updated_at   :datetime         not null
#  user_id      :integer
#
# Indexes
#
#  index_deal_activations_on_deal_id_and_user_id  (deal_id,user_id) UNIQUE
#

