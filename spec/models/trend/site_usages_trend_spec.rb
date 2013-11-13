require 'spec_helper'

describe SiteUsagesTrend do

  describe '.json' do
    before do
      create(:site_usages_trend, d: Time.now.utc.midnight)
    end
    subject { JSON.parse(described_class.json) }

    describe '#size' do
      subject { super().size }
      it { should eq 1 }
    end
    it { expect(subject[0]['id']).to eq(Time.now.utc.midnight.to_i) }
    it { expect(subject[0]).to have_key('lh') }
    it { expect(subject[0]).to have_key('ph') }
    it { expect(subject[0]).to have_key('fh') }
    it { expect(subject[0]).to have_key('sr') }
    it { expect(subject[0]).to have_key('tr') }
  end

end
