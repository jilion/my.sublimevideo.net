require 'spec_helper'

describe GoodbyeFeedback do

  describe 'Factory' do
    subject { build(:goodbye_feedback) }

    its(:user_id) { should be_present }
    its(:reason)  { should eq 'support' }
  end

  describe 'Validations' do
    subject { create(:goodbye_feedback) }

    [:next_player, :reason, :comment].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end

    described_class::REASONS.each do |reason|
      it { should allow_value(reason).for(:reason) }
    end
    it { should_not allow_value('unknown').for(:reason) }
  end # Validations

end

# == Schema Information
#
# Table name: goodbye_feedbacks
#
#  id          :integer          not null, primary key
#  user_id     :integer          not null
#  next_player :string(255)
#  reason      :string(255)      not null
#  comment     :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_goodbye_feedbacks_on_user_id  (user_id) UNIQUE
#

