require 'spec_helper'

describe Site::Api do
  
  describe "#to_api" do
    before(:all) do
      @site = Factory(:site, hostname: 'rymai.me', dev_hostnames: 'rymai.local', extra_hostnames: 'rymai.com', last_30_days_main_player_hits_total_count: 10, last_30_days_extra_player_hits_total_count: 20)
    end
    subject { @site }
    
    it "should select a subset of fields" do
      puts "puts!!!!!!!!!!!!!!"
      puts Time.now.utc.midnight
      puts Time.now.utc.midnight.to_datetime
      puts Time.now.utc.midnight.to_datetime.utc
      
      puts subject.to_api[:plan].inspect
      subject.to_api[:plan].should == an_instance_of(Hash)
      
      subject.to_api.should == {
        token: subject.token,
        main_domain: 'rymai.me',
        dev_domains: ['rymai.local'],
        extra_domains: ['rymai.com'],
        wildcard: false,
        path: nil,
        plan: an_instance_of(Hash),
        next_plan: {},
        started_at: Time.now.utc.to_datetime.midnight,
        cycle_started_at: Time.now.utc.to_datetime.midnight,
        cycle_ended_at: 1.month.from_now.end_of_day - 1.day,
        refundable: true,
        peak_insurance_activated: false,
        upgrade_required: false,
        last_30_days_video_pageviews: 30
      }
    end
  end
  
end
