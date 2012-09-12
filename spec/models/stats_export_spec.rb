require 'spec_helper'

describe StatsExport do
  let(:csv)  { fixture_file('stats_export.csv') }
  let(:site) { create(:site) }
  let(:attributes) { {
    st: site.token,
    from: 30.days.ago.midnight.to_i,
    to: 1.days.ago.midnight.to_i,
    file: csv
  } }
  let(:stats_export) { StatsExport.create(attributes) }

  it { should validate_presence_of(:st) }
  it { should validate_presence_of(:from) }
  it { should validate_presence_of(:to) }
  it { should validate_presence_of(:file) }

  it "has a unique token id" do
    stats_export.id.should =~ /^[a-z0-9]{8}$/
    stats_export._id.should =~ /^[a-z0-9]{8}$/
  end

  describe "#site" do
    specify { stats_export.site.should eq site }
  end

  describe "#site_hostname" do
    specify { stats_export.site_hostname.should eq site.hostname }
  end
end
