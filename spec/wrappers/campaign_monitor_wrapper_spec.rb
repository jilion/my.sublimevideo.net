require 'fast_spec_helper'
require 'config/vcr'
require 'ostruct'

require 'wrappers/campaign_monitor_wrapper'

describe CampaignMonitorWrapper, :vcr do

  specify { expect(ENV['CAMPAIGN_MONITOR_API_KEY']).to eq '8844ec1803ffbe65bf192aa910e53d18' }
  specify { expect(described_class.list[:list_id]).to eq 'a064dfc4b8ccd774252a2e9c9deb9244' }
  specify { expect(described_class.list[:segment]).to eq 'test' }

  before do
    allow(described_class).to receive(:_log_bad_request).and_return(true)
    allow(Librato).to receive(:increment)
  end

  let(:subscribe_user) { OpenStruct.new(id: 12, beta?: true, newsletter?: true, email: 'user_subscribe3@example.org', name: 'User Subscribe') }

  describe '.subscribe' do

    it 'subscribes a user' do
      expect(described_class.subscribe(
        list_id: described_class.list[:list_id],
        segment: described_class.list[:segment],
        id: subscribe_user.id,
        email: subscribe_user.email,
        name: subscribe_user.name,
        beta: subscribe_user.beta?
      )).to be_truthy
    end
  end

  describe '.import' do
    let(:user1) { OpenStruct.new(id: 13, beta?: true, billable: false, email: 'user_import1@example.org', name: 'User Import #1') }
    let(:user2) { OpenStruct.new(id: 14, beta?: false, billable: true, email: 'user_import2@example.org', name: 'User Import #2') }

    it 'subscribes a list of user' do
      expect(described_class.import([
        { id: user1.id, email: user1.email, name: user1.name, beta: user1.beta?, billable: user1.billable },
        { id: user2.id, email: user2.email, name: user2.name, beta: user2.beta?, billable: user2.billable }
      ])).to be_truthy

      # user 1
      subscriber = CreateSend::Subscriber.get(described_class.auth, described_class.list[:list_id], user1.email)
      expect(subscriber['EmailAddress']).to eq user1.email
      expect(subscriber['Name']).to         eq user1.name
      expect(subscriber['State']).to        eq 'Active'
      expect(subscriber['CustomFields'].find { |h| h.values.include?('segment') }['Value']).to eq described_class.list[:segment]
      expect(subscriber['CustomFields'].find { |h| h.values.include?('user_id') }['Value']).to eq '13'
      expect(subscriber['CustomFields'].find { |h| h.values.include?('beta') }['Value']).to eq 'true'
      expect(subscriber['CustomFields'].find { |h| h.values.include?('billable') }['Value']).to eq 'false'
      # user 2
      subscriber = CreateSend::Subscriber.get(described_class.auth, described_class.list[:list_id], user2.email)
      expect(subscriber['EmailAddress']).to eq user2.email
      expect(subscriber['Name']).to         eq user2.name
      expect(subscriber['State']).to        eq 'Active'
      expect(subscriber['CustomFields'].find { |h| h.values.include?('segment') }['Value']).to eq described_class.list[:segment]
      expect(subscriber['CustomFields'].find { |h| h.values.include?('user_id') }['Value']).to eq '14'
      expect(subscriber['CustomFields'].find { |h| h.values.include?('beta') }['Value']).to eq 'false'
      expect(subscriber['CustomFields'].find { |h| h.values.include?('billable') }['Value']).to eq 'true'
    end
  end

  describe '.unsubscribe' do
    let(:user) { OpenStruct.new(id: 13, email: 'user_unsubscribe@example.org', name: 'User Unsubscribe') }

    before do
      expect(described_class.subscribe(
        list_id: described_class.list[:list_id],
        segment: described_class.list[:segment],
        id: user.id,
        email: user.email,
        name: user.name
      )).to be_truthy
    end

    it 'should unsubscribe an existing subscribed user' do
      expect(described_class.unsubscribe(user.email)).to be_truthy

      expect(described_class.subscriber(user.email)['State']).to eq 'Unsubscribed'
    end
  end

  describe '.update' do
    let(:user) { OpenStruct.new(id: 15, email: 'update_update15@super.com', name: 'User Update') }

    before {
      described_class.subscribe(
        list_id: described_class.list[:list_id],
        segment: described_class.list[:segment],
        id: user.id,
        email: user.email,
        name: user.name
      )
      described_class.unsubscribe(user.email)
      @subscriber = described_class.subscriber(user.email)
    }

    it 'works' do
      expect(@subscriber['State']).to eq 'Unsubscribed'
      expect(described_class.update(
        old_email: user.email, email: 'user_update16@example.org', name: 'John Doe', newsletter: true
      )).to be_truthy

      subscriber = described_class.subscriber('user_update16@example.org')
      expect(subscriber['EmailAddress']).to eq 'user_update16@example.org'
      expect(subscriber['Name']).to eq 'John Doe'
      expect(subscriber['State']).to eq 'Active'
    end
  end

  describe '.subscriber' do
    context 'exists' do
      it 'retrieve the subscriber' do
        subscriber = described_class.subscriber(subscribe_user.email)
        expect(subscriber['EmailAddress']).to eq subscribe_user.email
        expect(subscriber['Name']).to         eq subscribe_user.name
        expect(subscriber['State']).to        eq 'Active'
        expect(subscriber['CustomFields'].find { |h| h.values.include?('segment') }['Value']).to eq described_class.list[:segment]
        expect(subscriber['CustomFields'].find { |h| h.values.include?('user_id') }['Value']).to eq subscribe_user.id.to_s
        expect(subscriber['CustomFields'].find { |h| h.values.include?('beta') }['Value']).to eq subscribe_user.beta?.to_s
      end
    end

    context "doesn't exist" do
      it 'returns nil' do
        expect(described_class.subscriber('foo@example.org')).to be_falsey
      end
    end
  end

end
