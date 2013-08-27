require 'spec_helper'

describe Feedback do

  describe 'Factory' do
    subject { build(:feedback) }

    its(:user_id) { should be_present }
    its(:reason)  { should eq 'support' }
  end

  describe 'Validations' do
    subject { create(:feedback) }

    described_class::REASONS.each do |reason|
      it { should allow_value(reason).for(:reason) }
    end
    it { should_not allow_value('unknown').for(:reason) }
  end # Validations

  describe '.new_trial_feedback' do
    it { described_class.new_trial_feedback(build(:user)).kind.should eq :trial }
  end

  describe '.new_account_cancellation_feedback' do
    it { described_class.new_account_cancellation_feedback(build(:user)).kind.should eq :account_cancellation }
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

