require 'fast_spec_helper'

require 'models/business_model'

describe BusinessModel do

  describe 'self.new_trial_date' do
    specify { described_class.new_trial_date.should eq Time.utc(2013, 2, 27, 18) }
  end

  describe 'self.days_for_trial' do
    before do
      described_class.stub(new_trial_date: Time.utc(2013, 2, 26, 18))
    end

    context 'with no billable item activity given' do
      specify { described_class.days_for_trial.should eq 7 }
    end

    context 'with a billable item activity created before the new trial date' do
      let(:billable_item_activity) { stub('billable_item_activity', created_at: Time.utc(2013, 2, 26, 17)) }
      specify { described_class.days_for_trial(billable_item_activity).should eq 30 }
    end

    context 'with a billable item activity created before the new trial date' do
      let(:billable_item_activity) { stub('billable_item_activity', created_at: Time.utc(2013, 2, 26, 19)) }
      specify { described_class.days_for_trial(billable_item_activity).should eq 7 }
    end
  end

  describe 'self.days_before_trial_end' do
    before do
      described_class.stub(new_trial_date: Time.utc(2013, 2, 26, 18))
    end

    context 'with no billable item activity given' do
      specify { described_class.days_before_trial_end.should eq [2] }
    end

    context 'with a billable item activity created before the new trial date' do
      let(:billable_item_activity) { stub('billable_item_activity', created_at: Time.utc(2013, 2, 26, 17)) }
      specify { described_class.days_before_trial_end(billable_item_activity).should eq [5] }
    end

    context 'with a billable item activity created before the new trial date' do
      let(:billable_item_activity) { stub('billable_item_activity', created_at: Time.utc(2013, 2, 26, 19)) }
      specify { described_class.days_before_trial_end(billable_item_activity).should eq [2] }
    end
  end

end
