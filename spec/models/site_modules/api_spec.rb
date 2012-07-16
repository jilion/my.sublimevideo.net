require 'spec_helper'

describe SiteModules::Api do

  describe "#to_api" do
    context "normal site" do      
      let(:site)     { create(:site, hostname: 'rymai.me', dev_hostnames: 'rymai.local', extra_hostnames: 'rymai.com', wildcard: true, path: 'test') }
      let(:response) { site.as_api_response(:v1_private_self) }

      it "selects a subset of fields, as a hash" do
        response.should be_a(Hash)
        response[:token].should eq site.token
        response[:main_domain].should eq 'rymai.me'
        response[:dev_domains].should eq ['rymai.local']
        response[:extra_domains].should eq ['rymai.com']
        response[:wildcard].should eq true
        response[:path].should eq 'test'
        response[:plan].should eq site.plan.as_api_response(:v1_private_self)
        response[:next_plan].should eq nil
        response[:started_at].to_i.should eq Time.now.utc.midnight.to_i
        response[:cycle_started_at].to_i.should eq Time.now.utc.midnight.to_i
        response[:cycle_ended_at].to_i.should eq (1.month.from_now.end_of_day - 1.day).to_i
        response[:peak_insurance_activated].should eq false
        response[:upgrade_required].should eq false
      end
    end

    context "site without optional fields" do
      let(:site) { 
        site = create(:site, plan_id: create(:plan, name: 'free', price: 0).id, hostname: 'rymai.me', extra_hostnames: nil, wildcard: false, path: nil)
        site.update_attribute(:dev_hostnames, nil)
        site
      }
      let(:response) { site.as_api_response(:v1_private_self) }      

      it "selects a subset of fields, as a hash" do
        response.should be_a(Hash)
        response[:token].should eq site.token
        response[:main_domain].should eq 'rymai.me'
        response[:dev_domains].should eq []
        response[:extra_domains].should eq []
        response[:wildcard].should eq false
        response[:path].should eq ''
        response[:plan].should eq site.plan.as_api_response(:v1_private_self)
        response[:next_plan].should eq nil
        response[:started_at].to_i.should eq Time.now.utc.midnight.to_i
        response[:cycle_started_at].should eq nil
        response[:cycle_ended_at].should eq nil
        response[:peak_insurance_activated].should eq false
        response[:upgrade_required].should eq false
      end
    end
  end

  describe "#usage_to_api" do
    context "with no usage" do
      let(:site)     { create(:site, hostname: 'rymai.me', dev_hostnames: 'rymai.local', extra_hostnames: 'rymai.com', wildcard: true, path: 'test') }
      let(:response) { site.as_api_response(:v1_private_usage) }   
         
      before do
        create(:site_usage, site_id: site.id, day: 61.days.ago.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400)
        create(:site_usage, site_id: site.id, day: 59.days.ago.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400)
        create(:site_usage, site_id: site.id, day: Time.now.utc.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400)
      end
      
      it "selects a subset of fields, as a hash" do
        response.should be_a(Hash)
        response[:token].should eq site.token
        response[:usage].should eq site.usages.between(60.days.ago.midnight, Time.now.utc.end_of_day).as_api_response(:v1_private_self)
      end
    end
  end

end
