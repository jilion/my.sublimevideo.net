require 'spec_helper'

describe CampaignMonitor do
  let(:user) { Factory.create(:user, email: "cm2@jilion.com", name: "John Doe", created_at: Time.utc(2010,10,10), invitation_token: nil) }

  specify { CampaignMonitor.api_key.should eq "8844ec1803ffbe6501c3d7e9cfa23bf3" }
  specify { CampaignMonitor.lists.sublimevideo.list_id.should eq "a064dfc4b8ccd774252a2e9c9deb9244" }
  specify { CampaignMonitor.lists.sublimevideo.segment.should eq "test" }
  specify { CampaignMonitor.lists.sublimevideo_newsletter.list_id.should eq "a064dfc4b8ccd774252a2e9c9deb9244" }

  describe ".subscribe" do
    use_vcr_cassette "campaign_monitor/subscribe"

    it "should subscribe a user" do
      CampaignMonitor.subscribe(user).should be_true
      subscriber = CampaignMonitor.subscriber(user.email)
      subscriber["EmailAddress"].should eq user.email
      subscriber["Name"].should         eq user.name
      subscriber["State"].should        eq "Active"
      subscriber["CustomFields"].detect { |h| h.values.include?("segment") }["Value"].should eq CampaignMonitor.lists.sublimevideo.segment
      subscriber["CustomFields"].detect { |h| h.values.include?("user_id") }["Value"].should be_present
      subscriber["CustomFields"].detect { |h| h.values.include?("beta") }["Value"].should eq "true"
    end

    it "should subscribe an unsubscribed user" do
      CampaignMonitor.subscribe(user).should be_true
      CampaignMonitor.subscriber(user.email)["State"].should eq "Active"
      CampaignMonitor.unsubscribe(user.email).should be_true
      CampaignMonitor.subscriber(user.email)["State"].should eq "Unsubscribed"
      CampaignMonitor.subscribe(user).should be_true
      CampaignMonitor.subscriber(user.email)["State"].should eq "Active"
    end
  end

  describe ".import" do
    use_vcr_cassette "campaign_monitor/import"

    it "should subscribe a list of user" do
      user1 = Factory.create(:user, email: "bob1@bob.com", created_at: Time.utc(2010,10,10), invitation_token: nil)
      user2 = Factory.create(:user, email: "bob2@bob.com", created_at: Time.utc(2011,10,10), invitation_token: nil)
      CampaignMonitor.import([user1, user2]).should be_true
      # user 1
      subscriber = CreateSend::Subscriber.get(CampaignMonitor.lists.sublimevideo.list_id, user1.email)
      subscriber["EmailAddress"].should eq user1.email
      subscriber["Name"].should         eq user1.name
      subscriber["State"].should        eq "Active"
      subscriber["CustomFields"].detect { |h| h.values.include?("segment") }["Value"].should eq CampaignMonitor.lists.sublimevideo.segment
      subscriber["CustomFields"].detect { |h| h.values.include?("user_id") }["Value"].should be_present
      subscriber["CustomFields"].detect { |h| h.values.include?("beta") }["Value"].should eq "true"
      # user 2
      subscriber = CreateSend::Subscriber.get(CampaignMonitor.lists.sublimevideo.list_id, user2.email)
      subscriber["EmailAddress"].should eq user2.email
      subscriber["Name"].should         eq user2.name
      subscriber["State"].should        eq "Active"
      subscriber["CustomFields"].detect { |h| h.values.include?("segment") }["Value"].should eq CampaignMonitor.lists.sublimevideo.segment
      subscriber["CustomFields"].detect { |h| h.values.include?("user_id") }["Value"].should be_present
      subscriber["CustomFields"].detect { |h| h.values.include?("beta") }["Value"].should eq "false"
    end
  end

  describe ".unsubscribe" do
    use_vcr_cassette "campaign_monitor/unsubscribe"

    it "should unsubscribe an existing subscribed user" do
      CampaignMonitor.subscribe(user)
      CampaignMonitor.subscriber(user.email)["State"].should eq "Active"

      CreateSend.api_key('invalid') # simulate a call to unsubscribe from a context where api_key is not set (here, not valid since when set to nil it takes the current value...), from within a delayed job for example

      CampaignMonitor.unsubscribe(user.email).should be_true
      CampaignMonitor.subscriber(user.email)["State"].should eq "Unsubscribed"
    end
  end

  describe ".update" do
    describe "updates email" do
      use_vcr_cassette "campaign_monitor/update_email"

      it "works" do
        CampaignMonitor.subscribe(user)
        CampaignMonitor.subscriber(user.email)["State"].should eq "Active"

        CreateSend.api_key('invalid') # simulate a call to unsubscribe from a context where api_key is not set (here, not valid since when set to nil it takes the current value...), from within a delayed job for example
        user.email = "#{rand(1000)}_#{user.email}"

        CampaignMonitor.update(user).should be_true
        user.save_skip_pwd
        # CampaignMonitor.subscriber(user.email)["EmailAddress"].should eq "cm_update_email@jilion.com"
        # CampaignMonitor.subscriber(user.email)["State"].should eq "Active"
      end
    end

    describe "updates first name" do
      use_vcr_cassette "campaign_monitor/update_name"

      it "works" do
        CampaignMonitor.subscribe(user)
        CampaignMonitor.subscriber(user.email)["State"].should eq "Active"

        CreateSend.api_key('invalid') # simulate a call to unsubscribe from a context where api_key is not set (here, not valid since when set to nil it takes the current value...), from within a delayed job for example
        user.name = "Joe Doe"

        CampaignMonitor.update(user).should be_true
        CampaignMonitor.subscriber(user.email)["Name"].should eq "Joe Doe"
        CampaignMonitor.subscriber(user.email)["State"].should eq "Active"
      end
    end

    describe "updates newsletter" do
      use_vcr_cassette "campaign_monitor/update_newsletter"

      it "works" do
        CampaignMonitor.subscribe(user)
        CampaignMonitor.unsubscribe(user.email).should be_true
        CampaignMonitor.subscriber(user.email)["State"].should eq "Unsubscribed"

        CreateSend.api_key('invalid') # simulate a call to unsubscribe from a context where api_key is not set (here, not valid since when set to nil it takes the current value...), from within a delayed job for example
        user.newsletter = true

        CampaignMonitor.update(user).should be_true
        CampaignMonitor.subscriber(user.email)["State"].should eq "Active"
      end
    end
  end

end
