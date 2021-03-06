require 'fast_spec_helper'

require 'models/preview_kit'

describe PreviewKit do

  describe '.kit_names' do
    it { described_class.kit_names.should eq %w[classic flat light html5 twit sony anthony next15 blizzard df] }
  end

  describe '.kit_identifer' do
    it { described_class.kit_identifer('classic').should eq '1' }
    it { described_class.kit_identifer('flat').should eq '2' }
    it { described_class.kit_identifer('light').should eq '3' }
    it { described_class.kit_identifer('html5').should eq '4' }
    it { described_class.kit_identifer('twit').should eq '5' }
    it { described_class.kit_identifer('sony').should eq '6' }
    it { described_class.kit_identifer('anthony').should eq '7' }
    it { described_class.kit_identifer('next15').should eq '8' }
    it { described_class.kit_identifer('blizzard').should eq '9' }
    it { described_class.kit_identifer('foo').should eq '1' }
  end

end
