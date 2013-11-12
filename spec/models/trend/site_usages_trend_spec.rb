require 'spec_helper'

describe SiteUsagesTrend do

  describe '.json' do
    before do
      create(:site_usages_trend, d: Time.now.utc.midnight)
    end
    subject { JSON.parse(described_class.json) }

    its(:size) { should eq 1 }
    it { subject[0]['id'].should eq(Time.now.utc.midnight.to_i) }
    it { subject[0].should have_key('lh') }
    it { subject[0].should have_key('ph') }
    it { subject[0].should have_key('fh') }
    it { subject[0].should have_key('sr') }
    it { subject[0].should have_key('tr') }
  end

end
