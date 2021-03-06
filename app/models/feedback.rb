class Feedback < ActiveRecord::Base
  belongs_to :user

  REASONS = %w[feature configuration integration price support other]

  # ==========
  # = Scopes =
  # ==========

  # sort
  scope :by_user,   ->(way = 'desc') { order(user_id: way.to_sym) }
  scope :by_kind,   ->(way = 'desc') { order(kind: way.to_sym) }
  scope :by_reason, ->(way = 'desc') { order(reason: way.to_sym) }
  scope :by_date,   ->(way = 'desc') { order(created_at: way.to_sym) }

  validates :reason, inclusion: REASONS

  def self.new_trial_feedback(user, *args)
    new_feedback(:trial, user, *args)
  end

  def self.new_account_cancellation_feedback(user, *args)
    new_feedback(:account_cancellation, user, *args)
  end

  def self.new_feedback(kind, user, *args)
    feedback = new(*args)
    feedback.kind = kind
    feedback.user_id = user.id

    feedback
  end
  private_class_method :new_feedback

end

# == Schema Information
#
# Table name: feedbacks
#
#  comment     :text
#  created_at  :datetime
#  id          :integer          not null, primary key
#  kind        :string(255)
#  next_player :string(255)
#  reason      :string(255)      not null
#  updated_at  :datetime
#  user_id     :integer          not null
#

