require 'fast_spec_helper'
require 'ostruct'

stub_module 'CampaignMonitorConfig'
stub_module 'User'

require_relative '../../../lib/newsletter_manager'

describe NewsletterManager do
  before do
    CampaignMonitorConfig.stub(lists: {
      'sublimevideo' => { 'list_id' => 'abc42', 'segment' => 'test' },
      'sublimevideo_newsletter' => { 'list_id' => 'bcd43' }
    })
  end
  let(:user1) { OpenStruct.new(id: 12, beta?: true, newsletter?: true, email_was: nil, email: 'user@example.org', name: 'User Example') }
  let(:user2) { OpenStruct.new(id: 13, beta?: false, newsletter?: true, email_was: 'old_user2@example.org', email: 'user2@example.org', name: 'User2 Example') }

  describe '.subscribe' do
    it 'delays CampaignMonitorWrapper.subscribe' do
      CampaignMonitorWrapper.should_receive(:delay).and_return(@dj = mock('delay'))
      @dj.should_receive(:subscribe).with(
        list_id: 'abc42', segment: 'test',
        user: { id: user1.id, email: user1.email, name: user1.name, beta: user1.beta?.to_s }
      )

      described_class.subscribe(user1)
    end
  end

  describe '.unsubscribe' do
    it 'delays CampaignMonitorWrapper.unsubscribe' do
      CampaignMonitorWrapper.should_receive(:delay).and_return(@dj = mock('delay'))
      @dj.should_receive(:unsubscribe).with(
        list_id: 'abc42', email: user1.email
      )

      described_class.unsubscribe(user1)
    end
  end

  describe '.import' do
    it 'delays CampaignMonitorWrapper.import' do
      CampaignMonitorWrapper.should_receive(:delay).and_return(@dj = mock('delay'))
      @dj.should_receive(:import).with(
        list_id: 'abc42', segment: 'test',
        users: [
          { id: user1.id, email: user1.email, name: user1.name, beta: user1.beta?.to_s },
          { id: user2.id, email: user2.email, name: user2.name, beta: user2.beta?.to_s }
        ]
      )

      described_class.import([user1, user2])
    end
  end

  describe '.sync_from_service' do
    it 'delays _sync_from_service' do
      described_class.should_receive(:delay).and_return(@dj = mock('delay'))
      @dj.should_receive(:_sync_from_service).with(user1.id)

      described_class.sync_from_service(user1)
    end
  end

  describe '._sync_from_service' do
    before do
      User.should_receive(:find).with(user1.id).and_return(user1)
    end

    context 'user is subscribed in CM' do
      before do
        CampaignMonitorWrapper.should_receive(:subscriber) { true }
      end

      it 'sets the newsletter attribute of the user' do
        user1.should_receive(:update_column).with(:newsletter, true)
        described_class.send(:_sync_from_service, user1.id)
      end
    end

    context "user isn't subscribed in CM" do
      before do
        CampaignMonitorWrapper.should_receive(:subscriber).twice { nil }
      end

      it 'set newsletter' do
        user1.should_not_receive(:update_column)
        described_class.send(:_sync_from_service, user1.id)
      end
    end
  end

  describe '.update' do
    context 'email of the user has not changed' do
      it 'delays CampaignMonitorWrapper.update' do
        CampaignMonitorWrapper.should_receive(:delay).and_return(@dj = mock('delay'))
        @dj.should_receive(:update).with(
          list_id: 'abc42',
          email: user1.email,
          user: { email: user1.email, name: user1.name, newsletter: user1.newsletter? }
        )

        described_class.update(user1)
      end
    end

    context 'email of the user has changed' do
      it 'delays CampaignMonitorWrapper.update' do
        CampaignMonitorWrapper.should_receive(:delay).and_return(@dj = mock('delay'))
        @dj.should_receive(:update).with(
          list_id: 'abc42',
          email: user2.email_was,
          user: { email: user2.email, name: user2.name, newsletter: user2.newsletter? }
        )

        described_class.update(user2)
      end
    end
  end

end
