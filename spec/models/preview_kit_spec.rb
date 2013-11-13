require 'fast_spec_helper'

require 'models/preview_kit'

describe PreviewKit do

  describe '.kit_names' do
    it { expect(described_class.kit_names).to eq %w[classic flat light html5 twit sony anthony next15 blizzard df] }
  end

  describe '.kit_identifer' do
    it { expect(described_class.kit_identifer('classic')).to eq '1' }
    it { expect(described_class.kit_identifer('flat')).to eq '2' }
    it { expect(described_class.kit_identifer('light')).to eq '3' }
    it { expect(described_class.kit_identifer('html5')).to eq '4' }
    it { expect(described_class.kit_identifer('twit')).to eq '5' }
    it { expect(described_class.kit_identifer('sony')).to eq '6' }
    it { expect(described_class.kit_identifer('anthony')).to eq '7' }
    it { expect(described_class.kit_identifer('next15')).to eq '8' }
    it { expect(described_class.kit_identifer('blizzard')).to eq '9' }
    it { expect(described_class.kit_identifer('foo')).to eq '1' }
  end

end
