require 'fast_spec_helper'
require File.expand_path('lib/service/user')

User = Class.new unless defined?(User)
UserMailer = Class.new unless defined?(UserMailer)

describe Service::User do
  let(:user)           { stub(id: 1234, sites: []) }
  let(:site1)          { stub(suspend: true) }
  let(:site2)          { stub(suspend: true) }
  let(:service)        { described_class.new(user) }
  let(:delayed_method) { stub }

  describe '.build' do
    it 'instantiate a new Service::Site and returns it' do
      User.should_receive(:new).with(email: 'test@example.com')

      described_class.build(email: 'test@example.com').should be_a(described_class)
    end
  end

  describe '#initial_save' do
    before do
      User.should_receive(:transaction).and_yield
      service.stub(:send_welcome_email) { true }
      service.stub(:sync_with_newsletter_service) { true }
    end

    context 'user is valid' do
      before do
        user.should_receive(:save) { true }
      end

      it 'sends the welcome email' do
        service.should_receive(:send_welcome_email)

        service.initial_save
      end

      it 'subscribes to the newsletter' do
        service.should_receive(:sync_with_newsletter_service)

        service.initial_save
      end
    end

    context 'user is not valid' do
      before do
        user.should_receive(:save) { false }
      end

      it 'returns false' do
        service.initial_save.should be_false
      end

      it 'doesnt send the welcome email nor subscribe to the newsletter' do
        service.should_not_receive(:send_welcome_email)
        service.should_not_receive(:sync_with_newsletter_service)

        service.initial_save
      end
    end
  end

  describe '#suspend' do
    before do
      User.should_receive(:transaction).and_yield
      service.stub(:send_account_suspended_email) { true }
      service.stub(:suspend_active_sites) { true }
    end

    context 'user is valid' do
      before do
        user.should_receive(:suspend) { true }
      end

      it 'sends the account suspended email' do
        service.should_receive(:send_account_suspended_email)

        service.suspend
      end

      it 'suspends active sites' do
        service.should_receive(:suspend_active_sites)

        service.suspend
      end
    end

    context 'user is not valid' do
      before do
        user.should_receive(:suspend) { false }
      end

      it 'returns false' do
        service.suspend.should be_false
      end

      it 'doesnt send the account suspended email nor suspend active sites' do
        service.should_not_receive(:send_account_suspended_email)
        service.should_not_receive(:suspend_active_sites)

        service.suspend
      end
    end
  end

  describe '#unsuspend' do
    before do
      User.should_receive(:transaction).and_yield
      service.stub(:send_account_unsuspended_email) { true }
      service.stub(:unsuspend_suspended_sites) { true }
    end

    context 'user is valid' do
      before do
        user.should_receive(:unsuspend) { true }
      end

      it 'sends the account unsuspended email' do
        service.should_receive(:send_account_unsuspended_email)

        service.unsuspend
      end

      it 'unsuspend suspended sites' do
        service.should_receive(:unsuspend_suspended_sites)

        service.unsuspend
      end
    end

    context 'user is not valid' do
      before do
        user.should_receive(:unsuspend) { false }
      end

      it 'returns false' do
        service.unsuspend.should be_false
      end

      it 'doesnt send the account unsuspended email nor unsuspend suspended sites' do
        service.should_not_receive(:send_account_unsuspended_email)
        service.should_not_receive(:unsuspend_suspended_sites)

        service.unsuspend
      end
    end
  end

  describe '#archive' do
    before do
      User.should_receive(:transaction).and_yield
      service.stub(:send_account_archived_email) { true }
    end

    context 'user is valid' do
      before do
        user.should_receive(:archive) { true }
      end

      it 'sends the account archived email' do
        service.should_receive(:send_account_archived_email)

        service.archive
      end
    end

    context 'user is not valid' do
      before do
        user.should_receive(:archive) { false }
      end

      it 'returns false' do
        service.archive.should be_false
      end

      it 'doesnt send the account archived email' do
        service.should_not_receive(:send_account_archived_email)

        service.archive
      end
    end
  end

  describe '#send_welcome_email' do
    it 'delays UserMailer#welcome' do
      UserMailer.should_receive(:delay) { delayed_method }
      delayed_method.should_receive(:welcome).with(user.id)

      service.send(:send_welcome_email)
    end
  end

  describe '#sync_with_newsletter_service' do
    it 'delays Service::Newsletter.sync_from_service' do
      Service::Newsletter.should_receive(:delay) { delayed_method }
      delayed_method.should_receive(:sync_from_service).with(user.id)

      service.send(:sync_with_newsletter_service)
    end
  end

  describe '#send_account_suspended_email' do
    it 'delays UserMailer#account_suspended' do
      UserMailer.should_receive(:delay) { delayed_method }
      delayed_method.should_receive(:account_suspended).with(user.id)

      service.send(:send_account_suspended_email)
    end
  end

  describe '#send_account_unsuspended_email' do
    it 'delays UserMailer#account_unsuspended' do
      UserMailer.should_receive(:delay) { delayed_method }
      delayed_method.should_receive(:account_unsuspended).with(user.id)

      service.send(:send_account_unsuspended_email)
    end
  end

  describe '#send_account_archived_email' do
    it 'delays UserMailer#account_archived' do
      UserMailer.should_receive(:delay) { delayed_method }
      delayed_method.should_receive(:account_archived).with(user.id)

      service.send(:send_account_archived_email)
    end
  end

  describe '#suspend_active_sites' do
    it 'calls :suspend on all active sites' do
      user.stub_chain(:sites, :active) { [site1, site2] }
      site1.should_receive(:suspend)
      site2.should_receive(:suspend)

      service.send(:suspend_active_sites)
    end
  end

  describe '#unsuspend_suspended_sites' do
    it 'calls :suspend on all active sites' do
      user.stub_chain(:sites, :suspended) { [site1, site2] }
      site1.should_receive(:unsuspend)
      site2.should_receive(:unsuspend)

      service.send(:unsuspend_suspended_sites)
    end
  end

end
