class Deal < ActiveRecord::Base
  has_many :deal_activations
  has_many :invoice_items

  validates :token, presence: true, uniqueness: true
  validates :name, :kind, :availability_scope, :started_at, :ended_at, presence: true

  scope :active, -> {
    now = Time.now.utc.to_s(:db)
    where("deals.started_at <= ? and deals.ended_at >= ?", now, now)
  }

  # sort
  scope :by_id,         ->(way = 'desc') { order(id: way.to_sym) }
  scope :by_started_at, ->(way = 'desc') { order(started_at: way.to_sym) }
  scope :by_ended_at,   ->(way = 'desc') { order(ended_at: way.to_sym) }

  before_validation :ensure_availability_scope_is_valid

  def active?
    (started_at..ended_at).cover?(Time.now.utc)
  end

  def available_to?(user)
    user && User.class_eval(availability_scope).where(id: user.id).present?
  end

private

  def ensure_availability_scope_is_valid
    User.class_eval(availability_scope)
    true
  rescue
    self.errors.add(:base, 'Scope is not valid.')
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

