require 'fast_spec_helper'

require 'sidekiq'
require File.expand_path('spec/config/sidekiq')
require File.expand_path('spec/support/sidekiq_custom_matchers')

require File.expand_path('lib/service/user')

User = Class.new unless defined?(User)
UserMailer = Class.new unless defined?(UserMailer)

describe Service::User do
  let(:user)           { stub(id: 1234, sites: [], save!: true) }
  let(:site1)          { stub(suspend: true) }
  let(:site2)          { stub(suspend: true) }
  let(:tokens)         { stub }
  let(:service)        { described_class.new(user) }
  let(:feedback)       { stub }

  describe '#create' do
    it 'saves user' do
      user.should_receive(:save!)
      service.create
    end

    pending 'delays the sending of the welcome email' do
      UserMailer.should delay(:welcome).with(user.id)
      service.create
    end

    it 'delays the synchronization with the newsletter service' do
      Service::Newsletter.should delay(:sync_from_service).with(user.id)
      service.create
    end

    it "increments metrics" do
      Librato.should_receive(:increment).with('users.events', source: 'create')
      service.create
    end
  end

  describe '#suspend' do
    before do
      User.should_receive(:transaction).and_yield
      user.stub_chain(:sites, :active) { [site1, site2] }
      user.stub(:suspend!)
      site1.stub(:suspend!)
      site2.stub(:suspend!)
    end

    it 'suspends user' do
      user.should_receive(:suspend!)
      service.suspend
    end

    it 'suspends active sites' do
      site1.should_receive(:suspend!)
      site2.should_receive(:suspend!)
      service.suspend
    end

    it 'delays the sending of the account suspended email' do
      UserMailer.should delay(:account_suspended).with(user.id)
      service.suspend
    end

    it "increments metrics" do
      Librato.should_receive(:increment).with('users.events', source: 'suspend')
      service.suspend
    end
  end

  describe '#unsuspend' do
    before do
      User.should_receive(:transaction).and_yield
      user.stub_chain(:sites, :suspended) { [site1, site2] }
      user.stub(:unsuspend!)
      site1.stub(:unsuspend!)
      site2.stub(:unsuspend!)
    end

    it 'unsuspends user' do
      user.should_receive(:unsuspend!)
      service.unsuspend
    end

    it 'suspends active sites' do
      site1.should_receive(:unsuspend!)
      site2.should_receive(:unsuspend!)
      service.unsuspend
    end

    it 'delays the sending of the account unsuspended email' do
      UserMailer.should delay(:account_unsuspended).with(user.id)
      service.unsuspend
    end

    it "increments metrics" do
      Librato.should_receive(:increment).with('users.events', source: 'unsuspend')
      service.unsuspend
    end
  end

  describe '#archive' do
    before do
      User.should_receive(:transaction).and_yield
      user.stub_chain(:sites, :not_archived) { [site1, site2] }
      user.stub_chain(:tokens) { tokens }
      tokens.stub(:update_all)
      user.stub(:archive!)
      user.stub(:archived_at=)
      feedback.stub(:user_id=)
      feedback.stub(:save!)
      site1.stub(:archive!)
      site2.stub(:archive!)
    end

    it "increments metrics" do
      Librato.should_receive(:increment).with('users.events', source: 'archive')
      service.archive
    end

    context 'without feedback' do
      it 'touches archived_at' do
        user.should_receive(:archived_at=)
        service.archive
      end

      it 'archives user' do
        user.should_receive(:archive!)
        service.archive
      end

      it 'archives sites' do
        site1.should_receive(:archive!)
        site2.should_receive(:archive!)
        service.archive
      end

      it 'invalidates tokens' do
        tokens.should_receive(:update_all).with(invalidated_at: an_instance_of(Time))
        service.archive
      end

      it 'delays the unsubscription from the newsletter' do
        Service::Newsletter.should delay(:unsubscribe).with(user.id)
        service.archive
      end

      it 'delays the sending of the account archived email' do
        UserMailer.should delay(:account_archived).with(user.id)
        service.archive
      end
    end

    context 'with feedback' do
      it 'sets feedback\'s user_id' do
        feedback.should_receive(:user_id=).with(user.id)
        service.archive(feedback)
      end

      it 'saves feedback' do
        feedback.should_receive(:save!)
        service.archive(feedback)
      end
    end
  end

end
