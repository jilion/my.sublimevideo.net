require 'fast_spec_helper'
require 'sidekiq'
require 'config/sidekiq'
require 'support/matchers/sidekiq_matchers'

require 'wrappers/campaign_monitor_wrapper'
require 'services/newsletter_subscription_manager'

User = Class.new unless defined?(User)

describe NewsletterSubscriptionManager do
  let(:user1) { OpenStruct.new(id: 12, beta?: true, newsletter?: true, email_was: nil, email: 'user@example.org', name: 'User Example') }
  let(:user2) { OpenStruct.new(id: 13, beta?: false, newsletter?: true, email_was: 'old_user2@example.org', email: 'user2@example.org', name: 'User2 Example') }
  let(:user3) { OpenStruct.new(id: 12, beta?: true, newsletter?: false, email_was: nil, email: 'user@example.org', name: 'User Example') }
  let(:service) { described_class.new(user1) }
  let(:stubbed_service) { double }

  describe '.subscribe' do
    it 'create a new instance and calls #subscribe on it' do
      User.should_receive(:find).with(user1.id) { user1 }
      described_class.should_receive(:new).with(user1) { stubbed_service }
      stubbed_service.should_receive(:subscribe)

      described_class.subscribe(user1.id)
    end
  end

  describe '.unsubscribe' do
    it 'create a new instance and calls #unsubscribe on it' do
      User.should_receive(:find).with(user1.id) { user1 }
      described_class.should_receive(:new).with(user1) { stubbed_service }
      stubbed_service.should_receive(:unsubscribe)

      described_class.unsubscribe(user1.id)
    end
  end

  describe '.update' do
    it 'create a new instance and calls #unsubscribe on it' do
      User.should_receive(:find).with(user1.id) { user1 }
      described_class.should_receive(:new).with(user1) { stubbed_service }
      stubbed_service.should_receive(:update).with({ email: 'test@test.com', user: { email: 'test@test.com', name: 'Toto', newsletter: true } })

      described_class.update(user1.id, { email: 'test@test.com', user: { email: 'test@test.com', name: 'Toto', newsletter: true } })
    end
  end

  describe '.import' do
    it 'delays CampaignMonitorWrapper.import' do
      CampaignMonitorWrapper.should delay(:import)

      described_class.import([user1, user2])
    end
  end

  describe '#subscribe' do
    it 'calls CampaignMonitorWrapper.subscribe' do
      CampaignMonitorWrapper.should_receive(:subscribe).with(
        id: user1.id, email: user1.email, name: user1.name, beta: user1.beta?.to_s, billable: ''
      )

      service.subscribe
    end
  end

  describe '#unsubscribe' do
    it 'calls CampaignMonitorWrapper.unsubscribe' do
      CampaignMonitorWrapper.should_receive(:unsubscribe).with(user1.email)

      service.unsubscribe
    end
  end

  describe '#update' do
    it 'calls CampaignMonitorWrapper.update' do
      CampaignMonitorWrapper.should_receive(:update).with(
        old_email: 'test@test.com', email: user1.email, name: user1.name, newsletter: true
      )

      service.update('test@test.com')
    end
  end

  describe '.sync_from_service' do
    context 'user is subscribed in our system' do
      before do
        User.should_receive(:find).with(user1.id).and_return(user1)
        CampaignMonitorWrapper.should_not_receive(:subscriber)
      end

      it 'sets the newsletter attribute of the user' do
        described_class.sync_from_service(user1.id)
      end
    end

    context 'user is not subscribed in our system' do
      before do
        User.should_receive(:find).with(user3.id).and_return(user3)
      end

      context 'user is subscribed in CM' do
        before do
          CampaignMonitorWrapper.should_receive(:subscriber) { true }
        end

        it 'sets the newsletter attribute of the user' do
          user3.should_receive(:update_column).with(:newsletter, true)
          described_class.sync_from_service(user3.id)
        end
      end

      context "user isn't subscribed in CM" do
        before do
          CampaignMonitorWrapper.should_receive(:subscriber) { nil }
        end

        it 'set newsletter' do
          user3.should_not_receive(:update_column)
          described_class.sync_from_service(user3.id)
        end
      end
    end
  end

end
