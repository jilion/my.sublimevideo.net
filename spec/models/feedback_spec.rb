require 'spec_helper'

describe Feedback do

  describe 'Factory' do
    subject { build(:feedback) }

    describe '#user_id' do
      subject { super().user_id }
      it { should be_present }
    end

    describe '#reason' do
      subject { super().reason }
      it  { should eq 'support' }
    end
  end

  describe 'Validations' do
    subject { create(:feedback) }

    described_class::REASONS.each do |reason|
      it { should allow_value(reason).for(:reason) }
    end
    it { should_not allow_value('unknown').for(:reason) }
  end # Validations

  describe '.new_trial_feedback' do
    it { expect(described_class.new_trial_feedback(build(:user)).kind).to eq :trial }
  end

  describe '.new_account_cancellation_feedback' do
    it { expect(described_class.new_account_cancellation_feedback(build(:user)).kind).to eq :account_cancellation }
  end

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

