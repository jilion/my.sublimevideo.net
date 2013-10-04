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
        stub.get("/private_api/site_admin_stats/last_days_starts?days=2") { |env| [200, {}, [42, 2].to_json] }
      end
    }

    it "returns starts array" do
      SiteAdminStat.last_days_starts(site, 2).should eq [42, 2]
    end
  end

  describe ".last_pages" do
    before do
      stub_api_for(described_class) do |stub|
        stub.get("/private_api/site_admin_stats/last_pages") { |env| [200, {}, ['http://example.com'].to_json] }
      end
    end

    it "returns array" do
      expect(described_class.last_pages(site)).to eq(['http://example.com'])
    end
  end

  describe ".total_admin_starts" do
    before do
      stub_api_for(described_class) do |stub|
        stub.get("/private_api/site_admin_stats") { |env| [200, {}, [
          { id: 1, st: { e: 1, w: 1 }},
          { id: 2, st: { e: 2, w: 2 }}
        ].to_json] }
      end
    end

    it "returns sum of all starts" do
      expect(described_class.total_admin_starts(site)).to eq 6
    end
  end

  describe ".total_admin_app_loads" do
    before do
      stub_api_for(described_class) do |stub|
        stub.get("/private_api/site_admin_stats") { |env| [200, {}, [
          { id: 1, al: { e: 1, i: 2 }},
          { id: 2, al: { em: 3, m: 4 }},
          { id: 3 }
        ].to_json] }
      end
    end

    it "returns sum of all app loads" do
      expect(described_class.total_admin_app_loads(site)).to eq 10
    end
  end

  describe ".last_30_days_admin_app_loads" do
    before do
      stub_api_for(described_class) do |stub|
        stub.get("/private_api/site_admin_stats") { |env| [200, {}, [
          { id: 1, al: { e: 1, i: 2 }},
          { id: 2, al: { e: 3, m: 4 }},
          { id: 3 }
        ].to_json] }
      end
    end

    it "returns sum of all app loads of type e" do
      expect(described_class.last_30_days_admin_app_loads(site, :e)).to eq 4
    end

    it "returns sum of all app loads of type m" do
      expect(described_class.last_30_days_admin_app_loads(site, :m)).to eq 4
    end
  end

end

