require 'fast_spec_helper'
require 'configurator'
require 'createsend'
require 'config/vcr'
require 'ostruct'

require 'wrappers/campaign_monitor_wrapper'

describe CampaignMonitorWrapper do

  specify { CampaignMonitorWrapper.api_key.should eq "8844ec1803ffbe6501c3d7e9cfa23bf3" }
  specify { CampaignMonitorWrapper.lists['sublimevideo']['list_id'].should eq "a064dfc4b8ccd774252a2e9c9deb9244" }
  specify { CampaignMonitorWrapper.lists['sublimevideo']['segment'].should eq "test" }
  specify { CampaignMonitorWrapper.lists['sublimevideo_newsletter']['list_id'].should eq "a064dfc4b8ccd774252a2e9c9deb9244" }

  before {
    described_class.stub(_log_bad_request: true)
    Librato.stub(:increment)
  }

  let(:subscribe_user) { OpenStruct.new(id: 12, beta: true, newsletter?: true, email: 'user_subscribe3@example.org', name: 'User Subscribe') }

  describe '.subscribe' do

    it 'subscribes a user' do
      subscriber = VCR.use_cassette 'campaign_monitor_wrapper/subscribe' do
        described_class.subscribe(
          list_id: CampaignMonitorWrapper.lists['sublimevideo']['list_id'],
          segment: CampaignMonitorWrapper.lists['sublimevideo']['segment'],
          user: { id: subscribe_user.id, email: subscribe_user.email, name: subscribe_user.name, beta: subscribe_user.beta }
        ).should be_true
      end
    end
  end

  describe '.import' do
    let(:user1) { OpenStruct.new(id: 13, beta: true, billable: false, email: 'user_import1@example.org', name: 'User Import #1') }
    let(:user2) { OpenStruct.new(id: 14, beta: false, billable: true, email: 'user_import2@example.org', name: 'User Import #2') }

    use_vcr_cassette 'campaign_monitor_wrapper/import'

    it 'subscribes a list of user' do
      described_class.import(
        list_id: CampaignMonitorWrapper.lists['sublimevideo']['list_id'],
        segment: CampaignMonitorWrapper.lists['sublimevideo']['segment'],
        users: [
          { id: user1.id, email: user1.email, name: user1.name, beta: user1.beta, billable: user1.billable },
          { id: user2.id, email: user2.email, name: user2.name, beta: user2.beta, billable: user2.billable }
        ]
      ).should be_true

      # user 1
      subscriber = CreateSend::Subscriber.get(CampaignMonitorWrapper.lists['sublimevideo']['list_id'], user1.email)
      subscriber['EmailAddress'].should eq user1.email
      subscriber['Name'].should         eq user1.name
      subscriber['State'].should        eq 'Active'
      subscriber['CustomFields'].find { |h| h.values.include?('segment') }['Value'].should eq CampaignMonitorWrapper.lists['sublimevideo']['segment']
      subscriber['CustomFields'].find { |h| h.values.include?('user_id') }['Value'].should eq '13'
      subscriber['CustomFields'].find { |h| h.values.include?('beta') }['Value'].should eq 'true'
      subscriber['CustomFields'].find { |h| h.values.include?('billable') }['Value'].should eq 'false'
      # user 2
      subscriber = CreateSend::Subscriber.get(CampaignMonitorWrapper.lists['sublimevideo']['list_id'], user2.email)
      subscriber['EmailAddress'].should eq user2.email
      subscriber['Name'].should         eq user2.name
      subscriber['State'].should        eq 'Active'
      subscriber['CustomFields'].find { |h| h.values.include?('segment') }['Value'].should eq CampaignMonitorWrapper.lists['sublimevideo']['segment']
      subscriber['CustomFields'].find { |h| h.values.include?('user_id') }['Value'].should eq '14'
      subscriber['CustomFields'].find { |h| h.values.include?('beta') }['Value'].should eq 'false'
      subscriber['CustomFields'].find { |h| h.values.include?('billable') }['Value'].should eq 'true'
    end
  end

  describe '.unsubscribe' do
    let(:user) { OpenStruct.new(id: 13, email: 'user_unsubscribe@example.org', name: 'User Unsubscribe') }

    use_vcr_cassette 'campaign_monitor_wrapper/unsubscribe'

    before do
      described_class.subscribe(
        list_id: CampaignMonitorWrapper.lists['sublimevideo']['list_id'],
        segment: CampaignMonitorWrapper.lists['sublimevideo']['segment'],
        user: { id: user.id, email: user.email, name: user.name }
      ).should be_true
    end

    it 'should unsubscribe an existing subscribed user' do
      described_class.unsubscribe(
        list_id: CampaignMonitorWrapper.lists['sublimevideo']['list_id'],
        email: user.email
      ).should be_true

      described_class.subscriber(user.email)['State'].should eq 'Unsubscribed'
    end
  end

  describe '.update' do
    let(:user) { OpenStruct.new(id: 13, email: 'user_update5@example.org', name: 'User Update') }

    before do
      VCR.use_cassette 'campaign_monitor_wrapper/update_1' do
        described_class.subscribe(
          list_id: CampaignMonitorWrapper.lists['sublimevideo']['list_id'],
          segment: CampaignMonitorWrapper.lists['sublimevideo']['segment'],
          user: { id: user.id, email: user.email, name: user.name }
        ).should be_true
        described_class.unsubscribe(
          list_id: CampaignMonitorWrapper.lists['sublimevideo']['list_id'],
          email: user.email
        ).should be_true
        subscriber = described_class.subscriber(user.email)
        subscriber['State'].should eq 'Unsubscribed'
      end
    end

    it 'works' do
      VCR.use_cassette 'campaign_monitor_wrapper/update_2' do
        described_class.update(
          list_id: CampaignMonitorWrapper.lists['sublimevideo']['list_id'],
          email: user.email,
          user: { email: 'user_update6@example.org', name: 'John Doe', newsletter: true }
        ).should be_true

        subscriber = described_class.subscriber('user_update6@example.org')
        subscriber['EmailAddress'].should eq 'user_update6@example.org'
        subscriber['Name'].should eq 'John Doe'
        subscriber['State'].should eq 'Active'
      end
    end
  end

  describe '.subscriber' do
    context 'exists' do
      it 'retrieve the subscriber' do
        subscriber = VCR.use_cassette 'campaign_monitor_wrapper/subscribe' do
          described_class.subscriber(subscribe_user.email)
        end
        subscriber['EmailAddress'].should eq subscribe_user.email
        subscriber['Name'].should         eq subscribe_user.name
        subscriber['State'].should        eq 'Active'
        subscriber['CustomFields'].find { |h| h.values.include?('segment') }['Value'].should eq CampaignMonitorWrapper.lists['sublimevideo']['segment']
        subscriber['CustomFields'].find { |h| h.values.include?('user_id') }['Value'].should eq subscribe_user.id.to_s
        subscriber['CustomFields'].find { |h| h.values.include?('beta') }['Value'].should eq subscribe_user.beta.to_s
      end
    end

    context 'doesn\'t exist' do
      use_vcr_cassette 'campaign_monitor_wrapper/subscriber_doesnt_exist'

      it 'returns nil' do
        described_class.subscriber('foo@example.org').should be_false
      end
    end
  end

end
