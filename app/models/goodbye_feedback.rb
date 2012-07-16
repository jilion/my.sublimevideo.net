class GoodbyeFeedback < ActiveRecord::Base

  belongs_to :user

  attr_accessible :next_player, :comment, :reason

  REASONS = %w[feature configuration integration price support other]

  validates :reason, inclusion: REASONS

end
# == Schema Information
#
# Table name: goodbye_feedbacks
#
#  id          :integer         not null, primary key
#  user_id     :integer         not null
#  next_player :string(255)
#  reason      :string(255)     not null
#  comment     :text
#  created_at  :datetime        not null
#  updated_at  :datetime        not null
#
# Indexes
#
#  index_goodbye_feedbacks_on_user_id  (user_id) UNIQUE
#
