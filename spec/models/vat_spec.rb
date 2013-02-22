require 'fast_spec_helper'

require 'models/vat'

describe Vat do

  describe 'self.for_country' do
    specify { described_class.for_country('CH').should eq 0.08 }
    specify { described_class.for_country('FR').should eq 0.00 }
    specify { described_class.for_country('CN').should eq 0.00 }
    specify { described_class.for_country('US').should eq 0.00 }
  end

  describe 'self.for_country?' do
    specify { described_class.for_country?('CH').should be_true }
    specify { described_class.for_country?('FR').should be_false }
    specify { described_class.for_country?('CN').should be_false }
    specify { described_class.for_country?('US').should be_false }
  end

end
