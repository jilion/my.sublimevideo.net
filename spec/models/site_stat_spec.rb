require 'fast_spec_helper'
require 'active_support/core_ext'
require 'support/private_api_helpers'

require 'site_stat'

describe SiteStat do
  let(:site_token) { 'site_token' }
  let(:site) { double(token: site_token) }

  describe ".last_days_starts" do
    before {
      stub_api_for(SiteStat) do |stub|
        stub.get("/private_api/site_stats/last_days_starts?site_token=#{site_token}&days=2") { |env| [200, {}, [42, 2].to_json] }
      end
    }

    it "returns starts array" do
      SiteStat.last_days_starts(site, 2).should eq [42, 2]
    end
  end

end
