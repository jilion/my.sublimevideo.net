require 'fast_spec_helper'

require 'models/vat'

describe Vat do

  describe '.for_country' do
    specify { expect(described_class.for_country('CH')).to eq 0.08 }
    specify { expect(described_class.for_country('FR')).to eq 0.00 }
    specify { expect(described_class.for_country('CN')).to eq 0.00 }
    specify { expect(described_class.for_country('US')).to eq 0.00 }
  end

  describe '.for_country?' do
    specify { expect(described_class.for_country?('CH')).to be_truthy }
    specify { expect(described_class.for_country?('FR')).to be_falsey }
    specify { expect(described_class.for_country?('CN')).to be_falsey }
    specify { expect(described_class.for_country?('US')).to be_falsey }
  end

end
