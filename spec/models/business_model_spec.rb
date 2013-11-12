require 'fast_spec_helper'

require 'models/business_model'

describe BusinessModel do

  describe '.days_for_trial' do
    specify { described_class.days_for_trial.should eq 7 }
  end

  describe '.days_before_trial_end' do
    specify { described_class.days_before_trial_end.should eq [2] }
  end

end
