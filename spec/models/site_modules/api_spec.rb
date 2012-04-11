require 'spec_helper'

describe SiteModules::Api do

  describe "#to_api" do
    context "normal site" do
      before(:all) do
        @site     = create(:site_not_in_trial, hostname: 'rymai.me', dev_hostnames: 'rymai.local', extra_hostnames: 'rymai.com', wildcard: true, path: 'test')
        @response = @site.as_api_response(:v1_private_self)
      end
      subject { @site }

      it "selects a subset of fields, as a hash" do
        @response.should be_a(Hash)
        @response[:token].should == subject.token
        @response[:main_domain].should == 'rymai.me'
        @response[:dev_domains].should == ['rymai.local']
        @response[:extra_domains].should == ['rymai.com']
        @response[:wildcard].should == true
        @response[:path].should == 'test'
        @response[:plan].should == subject.plan.as_api_response(:v1_private_self)
        @response[:next_plan].should == nil
        @response[:started_at].to_i.should == Time.now.utc.midnight.to_i
        @response[:cycle_started_at].to_i.should == Time.now.utc.midnight.to_i
        @response[:cycle_ended_at].to_i.should == (1.month.from_now.end_of_day - 1.day).to_i
        @response[:peak_insurance_activated].should == false
        @response[:upgrade_required].should == false
      end
    end

    context "site without optional fields" do
      before(:all) do
        @site     = create(:new_site, hostname: 'rymai.me', extra_hostnames: nil, wildcard: false, path: nil, plan_started_at: nil, plan_cycle_started_at: nil, plan_cycle_ended_at: nil)
        @site.update_attribute(:dev_hostnames, nil)
        @response = @site.as_api_response(:v1_private_self)
      end
      subject { @site }

      it "selects a subset of fields, as a hash" do
        @response.should be_a(Hash)
        @response[:token].should == subject.token
        @response[:main_domain].should == 'rymai.me'
        @response[:dev_domains].should == []
        @response[:extra_domains].should == []
        @response[:wildcard].should == false
        @response[:path].should == ''
        @response[:plan].should == subject.plan.as_api_response(:v1_private_self)
        @response[:next_plan].should == nil
        @response[:started_at].to_i.should == Time.now.utc.midnight.to_i
        @response[:cycle_started_at].should == nil
        @response[:cycle_ended_at].should == nil
        @response[:peak_insurance_activated].should == false
        @response[:upgrade_required].should == false
      end
    end
  end

  describe "#usage_to_api" do
    context "with no usage" do
      before do
        @site        = create(:site, hostname: 'rymai.me', dev_hostnames: 'rymai.local', extra_hostnames: 'rymai.com', wildcard: true, path: 'test')
        @site_usage1 = create(:site_usage, site_id: @site.id, day: 61.days.ago.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400)
        @site_usage2 = create(:site_usage, site_id: @site.id, day: 59.days.ago.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400)
        @site_usage3 = create(:site_usage, site_id: @site.id, day: Time.now.utc.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400)
        @response    = @site.as_api_response(:v1_private_usage)
      end
      subject { @site }

      it "selects a subset of fields, as a hash" do
        @response.should be_a(Hash)
        @response[:token].should == subject.token
        @response[:usage].should == subject.usages.between(60.days.ago.midnight, Time.now.utc.end_of_day).as_api_response(:v1_private_self)
      end
    end
  end

end
