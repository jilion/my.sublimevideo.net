require 'fast_spec_helper'
require 'active_support/core_ext'
require 'support/private_api_helpers'

require 'site_admin_stat'

describe SiteAdminStat do
  let(:site_token) { 'site_token' }
  let(:site) { double(token: site_token) }

  describe ".last_days_starts" do
    before {
      stub_api_for(SiteAdminStat) do |stub|
        stub.get("/private_api/sites/#{site_token}/site_admin_stats/last_days_starts?days=2") { |env| [200, {}, { starts: [42, 2] }.to_json] }
      end
    }

    it "returns starts array" do
      SiteAdminStat.last_days_starts(site, 2).should eq [42, 2]
    end
  end

  describe ".last_pages" do
    before do
      stub_api_for(described_class) do |stub|
        stub.get("/private_api/sites/#{site_token}/site_admin_stats/last_pages") { |env| [200, {}, { pages: ['http://example.com'] }.to_json] }
      end
    end

    it "returns array" do
      expect(described_class.last_pages(site)).to eq(['http://example.com'])
    end
  end

  describe ".last_stats" do
    before do
      stub_api_for(described_class) do |stub|
        stub.get("/private_api/sites/#{site_token}/site_admin_stats") { |env| [200, {}, { stats: [{ id: 1 }] }.to_json] }
      end
    end

    it "returns last stats" do
      expect(described_class.last_stats(site).first).to eq SiteAdminStat.new(id: 1)
    end
  end

end

