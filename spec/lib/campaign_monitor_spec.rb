require 'spec_helper'

describe CampaignMonitor do
  let(:user) { FactoryGirl.create(:user, email: "cm2@jilion.com", created_at: Time.utc(2010,10,10), invitation_token: nil) }

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
      subscriber["CustomFields"].detect { |h| h.values.include?("beta") }["Value"].should == "true"
    end

    it "should subscribe an unsubscribed user" do
      CampaignMonitor.subscribe(user).should be_true
      CampaignMonitor.state(user.email) == "Active"
      CampaignMonitor.unsubscribe(user).should be_true
      CampaignMonitor.state(user.email) == "Unsubscribed"
      CampaignMonitor.subscribe(user).should be_true
      CampaignMonitor.state(user.email) == "Active"
    end

  end

  describe ".import" do
    use_vcr_cassette "campaign_monitor/import"

    it "should subscribe a list of user" do
      user1 = FactoryGirl.create(:user, email: "bob1@bob.com", created_at: Time.utc(2010,10,10), invitation_token: nil)
      user2 = FactoryGirl.create(:user, email: "bob2@bob.com", created_at: Time.utc(2011,10,10), invitation_token: nil)
      CampaignMonitor.import([user1, user2]).should be_true
      # user 1
      subscriber = CreateSend::Subscriber.get(CampaignMonitor.list_id, user1.email)
      subscriber["EmailAddress"].should == user1.email
      subscriber["Name"].should         == user1.full_name
      subscriber["State"].should        == "Active"
      subscriber["CustomFields"].detect { |h| h.values.include?("segment") }["Value"].should == CampaignMonitor.segment
      subscriber["CustomFields"].detect { |h| h.values.include?("user_id") }["Value"].should be_present
      subscriber["CustomFields"].detect { |h| h.values.include?("beta") }["Value"].should == "true"
      # user 2
      subscriber = CreateSend::Subscriber.get(CampaignMonitor.list_id, user2.email)
      subscriber["EmailAddress"].should == user2.email
      subscriber["Name"].should         == user2.full_name
      subscriber["State"].should        == "Active"
      subscriber["CustomFields"].detect { |h| h.values.include?("segment") }["Value"].should == CampaignMonitor.segment
      subscriber["CustomFields"].detect { |h| h.values.include?("user_id") }["Value"].should be_present
      subscriber["CustomFields"].detect { |h| h.values.include?("beta") }["Value"].should == "false"
    end

  end


  describe ".unsubscribe" do
    use_vcr_cassette "campaign_monitor/unsubscribe"

    it "should unsubscribe an existing subscribed user" do
      CampaignMonitor.subscribe(user).should be_true
      CampaignMonitor.state(user.email) == "Active"
      CreateSend.api_key('invalid') # simulate a call to unsubscribe from a context where api_key is not set (here, not valid since when set to nil it takes the current value...), from within a delayed job for example
      CampaignMonitor.unsubscribe(user).should be_true
      CampaignMonitor.state(user.email) == "Unsubscribed"
    end

  end

end