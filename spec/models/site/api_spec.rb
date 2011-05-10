require 'spec_helper'

describe Site::Api do

  describe "#to_api" do
    before(:all) do
      @site = Factory(:site, hostname: 'rymai.me', dev_hostnames: 'rymai.local', extra_hostnames: 'rymai.com', last_30_days_main_player_hits_total_count: 10, last_30_days_extra_player_hits_total_count: 20)
    end
    subject { @site }

    it "selects a subset of fields, as a hash" do
      hash = subject.to_api

      hash.should be_a(Hash)
      hash[:token].should == subject.token
      hash[:main_domain].should == 'rymai.me'
      hash[:dev_domains].should == ['rymai.local']
      hash[:extra_domains].should == ['rymai.com']
      hash[:wildcard].should == false
      hash[:path].should == nil
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

end
