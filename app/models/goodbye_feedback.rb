class GoodbyeFeedback < ActiveRecord::Base

  belongs_to :user

  attr_accessible :next_player, :comment, :reason

  REASONS = %w[feature configuration integration price support other]

  validates :reason, inclusion: REASONS

end
