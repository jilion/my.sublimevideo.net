require 'spec_helper'

describe CampaignMonitor do
  let(:user) { Factory(:user, :email => "cm@jilion.com") }

  specify { CampaignMonitor.api_key.should == "8844ec1803ffbe6501c3d7e9cfa23bf3" }
  specify { CampaignMonitor.list_id.should == "a064dfc4b8ccd774252a2e9c9deb9244" }
  specify { CampaignMonitor.segment.should == "test" }

  describe ".subscribe" do
    use_vcr_cassette "campaign_monitor/subscribe"

    it "should subscribe a user" do
      CampaignMonitor.subscribe(user).should be_true
      subscriber = CreateSend::Subscriber.get(CampaignMonitor.list_id, user.email)
      subscriber["EmailAddress"].should == user.email
      subscriber["Name"].should         == user.full_name
      subscriber["State"].should        == "Active"
      subscriber["CustomFields"].detect { |h| h.values.include?("segment") }["Value"].should == CampaignMonitor.segment
      subscriber["CustomFields"].detect { |h| h.values.include?("user_id") }["Value"].should be_present
    end

    it "should subscribe an unsubscribed user" do
      CampaignMonitor.subscribe(user).should be_true
      CampaignMonitor.state(user.email) == "Active"
      CampaignMonitor.unsubscribe(user.email).should be_true
      CampaignMonitor.state(user.email) == "Unsubscribed"
      CampaignMonitor.subscribe(user).should be_true
      CampaignMonitor.state(user.email) == "Active"
    end

  end

  describe ".import", :focus => true do
    use_vcr_cassette "campaign_monitor/import", :record => :all

    it "should subscribe a list of user" do
      user1 = Factory(:user, :email => "cm1@jilion.com")
      user2 = Factory(:user, :email => "cm2@jilion.com")
      CampaignMonitor.import([user1, user2]).should be_true
      # user 1
      subscriber = CreateSend::Subscriber.get(CampaignMonitor.list_id, user1.email)
      subscriber["EmailAddress"].should == user1.email
      subscriber["Name"].should         == user1.full_name
      subscriber["State"].should        == "Active"
      subscriber["CustomFields"].detect { |h| h.values.include?("segment") }["Value"].should == CampaignMonitor.segment
      subscriber["CustomFields"].detect { |h| h.values.include?("user_id") }["Value"].should be_present
      # user 2
      subscriber = CreateSend::Subscriber.get(CampaignMonitor.list_id, user2.email)
      subscriber["EmailAddress"].should == user2.email
      subscriber["Name"].should         == user2.full_name
      subscriber["State"].should        == "Active"
      subscriber["CustomFields"].detect { |h| h.values.include?("segment") }["Value"].should == CampaignMonitor.segment
      subscriber["CustomFields"].detect { |h| h.values.include?("user_id") }["Value"].should be_present
    end

  end


  describe ".unsubscribe" do
    use_vcr_cassette "campaign_monitor/unsubscribe"

    it "should unsubscribe an existing subscribed user" do
      CampaignMonitor.subscribe(user).should be_true
      CampaignMonitor.state(user.email) == "Active"
      CampaignMonitor.unsubscribe(user.email).should be_true
      CampaignMonitor.state(user.email) == "Unsubscribed"
    end

  end

end