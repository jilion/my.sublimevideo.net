require 'spec_helper'

describe Site::Api do

  describe "#to_api" do
    context "normal site" do
      before(:all) do
        @site = Factory(:site, hostname: 'rymai.me', dev_hostnames: 'rymai.local', extra_hostnames: 'rymai.com', wildcard: true, path: 'test')
      end
      subject { @site }

      it "selects a subset of fields, as a hash" do
        hash = subject.to_api

        hash.should be_a(Hash)
        hash[:token].should == subject.token
        hash[:main_domain].should == 'rymai.me'
        hash[:dev_domains].should == ['rymai.local']
        hash[:extra_domains].should == ['rymai.com']
        hash[:wildcard].should == true
        hash[:path].should == 'test'
        hash[:plan].should == subject.plan.to_api
        hash[:next_plan].should == {}
        hash[:started_at].to_i.should == Time.now.utc.midnight.to_i
        hash[:cycle_started_at].to_i.should == Time.now.utc.midnight.to_i
        hash[:cycle_ended_at].to_i.should == (1.month.from_now.end_of_day - 1.day).to_i
        hash[:refundable].should == true
        hash[:peak_insurance_activated].should == false
        hash[:upgrade_required].should == false
      end
    end

    context "site without optional fields" do
      before(:all) do
        @site = Factory(:new_site, hostname: 'rymai.me', extra_hostnames: nil, wildcard: false, path: nil, plan_started_at: nil, plan_cycle_started_at: nil, plan_cycle_ended_at: nil)
        @site.update_attribute(:dev_hostnames, nil)
      end
      subject { @site }

      it "selects a subset of fields, as a hash" do
        hash = subject.to_api

        hash.should be_a(Hash)
        hash[:token].should == subject.token
        hash[:main_domain].should == 'rymai.me'
        hash[:dev_domains].should == []
        hash[:extra_domains].should == []
        hash[:wildcard].should == false
        hash[:path].should == ''
        hash[:plan].should == {}
        hash[:next_plan].should == {}
        hash[:started_at].should == nil
        hash[:cycle_started_at].should == nil
        hash[:cycle_ended_at].should == nil
        hash[:refundable].should == false
        hash[:peak_insurance_activated].should == false
        hash[:upgrade_required].should == false
      end
    end
  end

  describe "#usage_to_api" do
    context "with no usage" do
      before(:each) do
        @site = Factory(:site, hostname: 'rymai.me', dev_hostnames: 'rymai.local', extra_hostnames: 'rymai.com', wildcard: true, path: 'test')
        @site_usage1 = Factory(:site_usage, site_id: @site.id, day: 61.days.ago.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400)
        @site_usage2 = Factory(:site_usage, site_id: @site.id, day: 59.days.ago.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400)
        @site_usage3 = Factory(:site_usage, site_id: @site.id, day: Time.now.utc.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400)
      end
      subject { @site }

      it "selects a subset of fields, as a hash" do
        hash = subject.usage_to_api

        hash.should be_a(Hash)
        hash[:token].should == subject.token
        hash[:usage].should == {
          @site_usage2.day.strftime("%Y-%m-%d") => @site_usage2.billable_player_hits,
          @site_usage3.day.strftime("%Y-%m-%d") => @site_usage3.billable_player_hits
        }
      end

      it "with dates given, selects a subset of fields, as a hash" do
        hash = subject.usage_to_api(15.days.ago, Time.now.utc.end_of_day)

        hash.should be_a(Hash)
        hash[:token].should == subject.token
        hash[:usage].should == {
          @site_usage3.day.strftime("%Y-%m-%d") => @site_usage3.billable_player_hits
        }
      end
    end
  end

end
