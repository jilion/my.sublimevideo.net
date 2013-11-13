require 'fast_spec_helper'

require 'models/business_model'

describe BusinessModel do

  describe '.days_for_trial' do
    specify { expect(described_class.days_for_trial).to eq 7 }
  end

  describe '.days_before_trial_end' do
    specify { expect(described_class.days_before_trial_end).to eq [2] }
  end

end
