class Feedback < ActiveRecord::Base

  belongs_to :user

  attr_accessible :next_player, :comment, :reason

  REASONS = %w[feature configuration integration price support other]

  # ==========
  # = Scopes =
  # ==========

  # sort
  scope :by_user,   lambda { |way='desc'| order(:user_id.send(way)) }
  scope :by_kind,   lambda { |way='desc'| order(:kind.send(way)) }
  scope :by_reason, lambda { |way='desc'| order(:reason.send(way)) }
  scope :by_date,   lambda { |way='desc'| order(:created_at.send(way)) }

  validates :reason, inclusion: REASONS

  def self.new_trial_feedback(*args)
    new_feedback(:trial, *args)
  end

  def self.new_account_cancellation_feedback(*args)
    new_feedback(:account_cancellation, *args)
  end

  private

  def self.new_feedback(kind, *args)
    feedback = new(*args)
    feedback.kind = kind

    feedback
  end

end

# == Schema Information
#
# Table name: feedbacks
#
#  comment     :text
#  created_at  :datetime         not null
#  id          :integer          not null, primary key
#  kind        :string(255)
#  next_player :string(255)
#  reason      :string(255)      not null
#  updated_at  :datetime         not null
#  user_id     :integer          not null
#

