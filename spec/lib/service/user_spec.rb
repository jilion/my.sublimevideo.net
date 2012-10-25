require 'fast_spec_helper'
require File.expand_path('lib/service/user')

User = Class.new unless defined?(User)
UserMailer = Class.new unless defined?(UserMailer)

describe Service::User do
  let(:user)           { stub(id: 1234, sites: []) }
  let(:site1)          { stub(suspend: true) }
  let(:site2)          { stub(suspend: true) }
  let(:tokens)         { stub }
  let(:service)        { described_class.new(user) }
  let(:delayed_method) { stub.as_null_object }
  let(:feedback)       { stub }

  describe '#create' do
    before do
      User.should_receive(:transaction).and_yield
      UserMailer.stub(:delay) { delayed_method }
      Service::Newsletter.stub(:delay) { delayed_method }
      user.stub(:save!)
    end

    it 'saves user' do
      user.should_receive(:save!)
      service.create
    end

    it 'delays the sending of the welcome email' do
      delayed_method.should_receive(:welcome).with(user.id)
      service.create
    end

    it 'delays the synchronization with the newsletter service' do
      delayed_method.should_receive(:sync_from_service).with(user.id)
      service.create
    end
  end

  describe '#suspend' do
    before do
      User.should_receive(:transaction).and_yield
      UserMailer.stub(:delay) { delayed_method }
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
      delayed_method.should_receive(:account_suspended)
      service.suspend
    end
  end

  describe '#unsuspend' do
    before do
      User.should_receive(:transaction).and_yield
      UserMailer.stub(:delay) { delayed_method }
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
      delayed_method.should_receive(:account_unsuspended)
      service.unsuspend
    end
  end

  describe '#archive' do
    before do
      User.should_receive(:transaction).and_yield
      UserMailer.stub(:delay) { delayed_method }
      Service::Newsletter.stub(:delay) { delayed_method }
      user.stub_chain(:sites) { [site1, site2] }
      user.stub_chain(:tokens) { tokens }
      tokens.stub(:update_all)
      user.stub(:archive!)
      user.stub(:archived_at=)
      feedback.stub(:user_id=)
      feedback.stub(:save!)
      site1.stub(:archive!)
      site2.stub(:archive!)
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
        delayed_method.should_receive(:unsubscribe).with(user.id)
        service.archive
      end

      it 'delays the sending of the account archived email' do
        delayed_method.should_receive(:account_archived)
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
