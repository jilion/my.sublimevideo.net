class Deal < ActiveRecord::Base

  attr_accessible :token, :name, :description, :kind, :value, :availability_scope, :started_at, :ended_at

  # ================
  # = Associations =
  # ================

  has_many :deal_activations
  has_many :invoice_items, class_name: 'InvoiceItems::InvoiceItem'

  # ===============
  # = Validations =
  # ===============

  validates :token, presence: true, uniqueness: true
  validates :name, :kind, :availability_scope, :started_at, :ended_at, presence: true

  # ==========
  # = Scopes =
  # ==========

  scope :active, lambda {
    now = Time.now.utc.to_s(:db)

    where{ (started_at <= now) & (ended_at >= now) }
  }

  # sort
  scope :by_id,         lambda { |way='desc'| order{ id.send(way) } }
  scope :by_started_at, lambda { |way='desc'| order{ started_at.send(way) } }
  scope :by_ended_at,   lambda { |way='desc'| order{ ended_at.send(way) } }

  # =============
  # = Callbacks =
  # =============

  before_validation :ensure_availability_scope_is_valid

  # ====================
  # = Instance Methods =
  # ====================

  def active?
    now = Time.now.utc

    now >= started_at && now <= ended_at
  end

  def available_to?(user)
    user && User.class_eval(availability_scope).where(id: user.id).present?
  end

private

  def ensure_availability_scope_is_valid
    User.class_eval(availability_scope)
    true
  rescue
    self.errors.add(:base, "Scope is not valid.")
  end

end

# == Schema Information
#
# Table name: deals
#
#  availability_scope :string(255)
#  created_at         :datetime         not null
#  description        :text
#  ended_at           :datetime
#  id                 :integer          not null, primary key
#  kind               :string(255)
#  name               :string(255)
#  started_at         :datetime
#  token              :string(255)
#  updated_at         :datetime         not null
#  value              :float
#
# Indexes
#
#  index_deals_on_token  (token) UNIQUE
#

