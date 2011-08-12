require 'spec_helper'

describe CampaignMonitor do
  let(:user) { FactoryGirl.create(:user, email: "cm2@jilion.com", first_name: "John", last_name: "Doe", created_at: Time.utc(2010,10,10), invitation_token: nil) }

  specify { CampaignMonitor.api_key.should eql "8844ec1803ffbe6501c3d7e9cfa23bf3" }
  specify { CampaignMonitor.list_id.should eql "a064dfc4b8ccd774252a2e9c9deb9244" }
  specify { CampaignMonitor.segment.should eql "test" }

  describe ".subscribe" do
    use_vcr_cassette "campaign_monitor/subscribe"

    it "should subscribe a user" do
      CampaignMonitor.subscribe(user).should be_true
      subscriber = CampaignMonitor.subscriber(user.email)
      subscriber["EmailAddress"].should eql user.email
      subscriber["Name"].should         eql user.full_name
      subscriber["State"].should        eql "Active"
      subscriber["CustomFields"].detect { |h| h.values.include?("segment") }["Value"].should == CampaignMonitor.segment
      subscriber["CustomFields"].detect { |h| h.values.include?("user_id") }["Value"].should be_present
      subscriber["CustomFields"].detect { |h| h.values.include?("beta") }["Value"].should == "true"
    end

    it "should subscribe an unsubscribed user" do
      CampaignMonitor.subscribe(user).should be_true
      CampaignMonitor.subscriber(user.email)["State"].should == "Active"
      CampaignMonitor.unsubscribe(user).should be_true
      CampaignMonitor.subscriber(user.email)["State"].should == "Unsubscribed"
      CampaignMonitor.subscribe(user).should be_true
      CampaignMonitor.subscriber(user.email)["State"].should == "Active"
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
      subscriber["EmailAddress"].should eql user1.email
      subscriber["Name"].should         eql user1.full_name
      subscriber["State"].should        eql "Active"
      subscriber["CustomFields"].detect { |h| h.values.include?("segment") }["Value"].should == CampaignMonitor.segment
      subscriber["CustomFields"].detect { |h| h.values.include?("user_id") }["Value"].should be_present
      subscriber["CustomFields"].detect { |h| h.values.include?("beta") }["Value"].should == "true"
      # user 2
      subscriber = CreateSend::Subscriber.get(CampaignMonitor.list_id, user2.email)
      subscriber["EmailAddress"].should eql user2.email
      subscriber["Name"].should         eql user2.full_name
      subscriber["State"].should        eql "Active"
      subscriber["CustomFields"].detect { |h| h.values.include?("segment") }["Value"].should == CampaignMonitor.segment
      subscriber["CustomFields"].detect { |h| h.values.include?("user_id") }["Value"].should be_present
      subscriber["CustomFields"].detect { |h| h.values.include?("beta") }["Value"].should == "false"
    end
  end

  describe ".unsubscribe" do
    use_vcr_cassette "campaign_monitor/unsubscribe"

    it "should unsubscribe an existing subscribed user" do
      CampaignMonitor.subscribe(user)
      CampaignMonitor.subscriber(user.email)["State"] == "Active"
      CreateSend.api_key('invalid') # simulate a call to unsubscribe from a context where api_key is not set (here, not valid since when set to nil it takes the current value...), from within a delayed job for example
      CampaignMonitor.unsubscribe(user.email).should be_true
      CampaignMonitor.subscriber(user.email)["State"].should eql "Unsubscribed"
    end
  end

  describe ".update" do
    describe "updates email" do
      use_vcr_cassette "campaign_monitor/update_email"

      it "works" do
        timestamp = Time.now.utc.to_i
        CampaignMonitor.subscribe(user)
        CampaignMonitor.subscriber(user.email)["State"].should eql "Active"

        CreateSend.api_key('invalid') # simulate a call to unsubscribe from a context where api_key is not set (here, not valid since when set to nil it takes the current value...), from within a delayed job for example
        user.email = "cm#{timestamp + 1}@jilion.com"

        CampaignMonitor.update(user).should be_true
        user.current_password = '123456'
        user.save!
        CampaignMonitor.subscriber(user.email)["EmailAddress"].should eql "cm#{timestamp + 1}@jilion.com"
        CampaignMonitor.subscriber(user.email)["State"].should eql "Active"
      end
    end

    describe "updates first name" do
      use_vcr_cassette "campaign_monitor/update_first_name"

      it "works" do
        CampaignMonitor.subscribe(user)
        CampaignMonitor.subscriber(user.email)["State"].should eql "Active"

        CreateSend.api_key('invalid') # simulate a call to unsubscribe from a context where api_key is not set (here, not valid since when set to nil it takes the current value...), from within a delayed job for example
        user.first_name = "Joe"

        CampaignMonitor.update(user).should be_true
        CampaignMonitor.subscriber(user.email)["Name"].should eql "Joe Doe"
        CampaignMonitor.subscriber(user.email)["State"].should eql "Active"
      end
    end

    describe "updates last name" do
      use_vcr_cassette "campaign_monitor/update_last_name"

      it "works" do
        CampaignMonitor.subscribe(user)
        CampaignMonitor.subscriber(user.email)["State"].should eql "Active"

        CreateSend.api_key('invalid') # simulate a call to unsubscribe from a context where api_key is not set (here, not valid since when set to nil it takes the current value...), from within a delayed job for example
        user.last_name = "Doooe"

        CampaignMonitor.update(user).should be_true
        CampaignMonitor.subscriber(user.email)["Name"].should eql "John Doooe"
        CampaignMonitor.subscriber(user.email)["State"].should eql "Active"
      end
    end

    describe "updates last name" do
      use_vcr_cassette "campaign_monitor/update_newsletter"

      it "works" do
        CampaignMonitor.subscribe(user)
        CampaignMonitor.unsubscribe(user.email).should be_true
        CampaignMonitor.subscriber(user.email)["State"].should eql "Unsubscribed"

        CreateSend.api_key('invalid') # simulate a call to unsubscribe from a context where api_key is not set (here, not valid since when set to nil it takes the current value...), from within a delayed job for example
        user.newsletter = true

        CampaignMonitor.update(user).should be_true
        CampaignMonitor.subscriber(user.email)["State"].should eql "Active"
      end
    end
  end

end