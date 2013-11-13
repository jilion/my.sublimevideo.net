require 'fast_spec_helper'
require 'sidekiq'
require 'config/sidekiq'
require 'support/matchers/sidekiq_matchers'

require 'services/newsletter_subscription_manager'
require 'services/user_manager'

User = Class.new unless defined?(User)
UserMailer = Class.new unless defined?(UserMailer)

describe UserManager do
  let(:user)           { double(id: 1234, sites: [], save!: true) }
  let(:site1)          { double(suspend: true) }
  let(:site2)          { double(suspend: true) }
  let(:tokens)         { double }
  let(:service)        { described_class.new(user) }
  let(:feedback)       { double }

  before {
    allow(Librato).to receive(:increment)
  }

  describe '#create' do
    it 'saves user' do
      expect(user).to receive(:save!)
      service.create
    end

    pending 'delays the sending of the welcome email' do
      expect(UserMailer).to delay(:welcome).with(user.id)
      service.create
    end

    it 'delays the synchronization with the newsletter service' do
      expect(NewsletterSubscriptionManager).to delay(:sync_from_service).with(user.id)
      service.create
    end

    it "increments metrics" do
      expect(Librato).to receive(:increment).with('users.events', source: 'create')
      service.create
    end
  end

  describe '#suspend' do
    before do
      expect(User).to receive(:transaction).and_yield
      user.stub_chain(:sites, :active) { [site1, site2] }
      allow(user).to receive(:suspend!)
      allow(site1).to receive(:suspend!)
      allow(site2).to receive(:suspend!)
    end

    it 'suspends user' do
      expect(user).to receive(:suspend!)
      service.suspend
    end

    it 'suspends active sites' do
      expect(site1).to receive(:suspend!)
      expect(site2).to receive(:suspend!)
      service.suspend
    end

    it 'delays the sending of the account suspended email' do
      expect(UserMailer).to delay(:account_suspended).with(user.id)
      service.suspend
    end

    it "increments metrics" do
      expect(Librato).to receive(:increment).with('users.events', source: 'suspend')
      service.suspend
    end
  end

  describe '#unsuspend' do
    before do
      expect(User).to receive(:transaction).and_yield
      user.stub_chain(:sites, :suspended) { [site1, site2] }
      allow(user).to receive(:unsuspend!)
      allow(site1).to receive(:unsuspend!)
      allow(site2).to receive(:unsuspend!)
    end

    it 'unsuspends user' do
      expect(user).to receive(:unsuspend!)
      service.unsuspend
    end

    it 'suspends active sites' do
      expect(site1).to receive(:unsuspend!)
      expect(site2).to receive(:unsuspend!)
      service.unsuspend
    end

    it 'delays the sending of the account unsuspended email' do
      expect(UserMailer).to delay(:account_unsuspended).with(user.id)
      service.unsuspend
    end

    it "increments metrics" do
      expect(Librato).to receive(:increment).with('users.events', source: 'unsuspend')
      service.unsuspend
    end
  end

  describe '#archive' do
    before do
      expect(User).to receive(:transaction).and_yield
      allow(user).to receive(:valid_password?) { true }
      allow(user).to receive(:current_password)
      user.stub_chain(:sites, :not_archived) { [site1, site2] }
      user.stub_chain(:tokens) { tokens }
      allow(tokens).to receive(:update_all)
      allow(user).to receive(:archive!)
      allow(feedback).to receive(:save!)
      allow(site1).to receive(:archive!)
      allow(site2).to receive(:archive!)
    end

    it 'increments metrics' do
      expect(Librato).to receive(:increment).with('users.events', source: 'archive')

      service.archive
    end

    describe 'options' do
      describe ':feedback option' do
        context 'with a feedback' do
          it 'saves feedback' do
            expect(feedback).to receive(:save!)

            service.archive(feedback: feedback)
          end
        end
      end

      describe ':skip_password option' do
        context 'set to true' do
          it 'calls skip_password(:archive!)' do
            expect(user).not_to receive(:valid_password?)
            expect(user).to receive(:archive!)

            service.archive(skip_password: true)
          end
        end
        context 'set to false' do
          it 'calls skip_password(:archive!)' do
            expect(user).to receive(:valid_password?)
            expect(user).to receive(:archive!)

            service.archive(skip_password: false)
          end
        end
      end
    end

    context 'with an invalid current password' do
      before do
        expect(user).to receive(:valid_password?) { false }
        allow(user).to receive(:current_password) { double(blank?: true) }
      end

      it 'adds an error and returns false' do
        expect(user).to receive(:errors) { double.as_null_object }

        expect(service.archive(skip_password: false)).to be_falsey
      end
    end

    context 'with an valid current password' do
      before { expect(user).to receive(:valid_password?) { true } }

      it 'adds an error and returns false' do
        expect(user).not_to receive(:errors)

        expect(service.archive(skip_password: false)).to be_truthy
      end
    end

    it 'archives the user' do
      expect(user).to receive(:archive!)

      service.archive
    end

    it 'archives the sites' do
      expect(site1).to receive(:archive!)
      expect(site2).to receive(:archive!)

      service.archive
    end

    it 'invalidates tokens' do
      expect(tokens).to receive(:update_all).with(invalidated_at: an_instance_of(Time))

      service.archive
    end

    it 'delays the unsubscription from the newsletter' do
      expect(NewsletterSubscriptionManager).to delay(:unsubscribe).with(user.id)

      service.archive
    end

    it 'delays the sending of the account archived email' do
      expect(UserMailer).to delay(:account_archived).with(user.id)

      service.archive
    end
  end

end
