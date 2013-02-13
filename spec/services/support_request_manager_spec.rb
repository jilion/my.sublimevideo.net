require 'fast_spec_helper'

require 'wrappers/zendesk_wrapper'
require 'services/support_request_manager'

SupportRequest = Struct.new(:params) unless defined?(SupportRequest)

describe SupportRequestManager do
  let(:user_without_zendesk_id) { mock('user', zendesk_id?: false) }
  let(:user_with_zendesk_id)    { mock('user', zendesk_id?: true) }
  let(:support_request1)        { mock('support_request', to_params: {}, user: user_without_zendesk_id) }
  let(:support_request2)        { mock('support_request', to_params: {}, user: user_with_zendesk_id) }
  let(:ticket)                  { mock('ticket', requester_id: 12, params: {}) }
  let(:manager1)                { described_class.new(support_request1) }
  let(:manager2)                { described_class.new(support_request2) }

  describe '.create_zendesk_user' do
    context 'user has a zendesk id' do
      let(:user) { stub(zendesk_id?: true) }

      it 'does nothing' do
        ZendeskWrapper.should_not_receive(:create_user)
        user.should_not_receive(:update_attribute)

        described_class.create_zendesk_user(user)
      end
    end

    context 'user has no zendesk id' do
      let(:user) { stub(zendesk_id?: false) }

      it 'create a user in Zendesk and set the zendesk_id from it' do
        ZendeskWrapper.should_receive(:create_user).with(user).and_return(OpenStruct.new(id: 42))
        user.should_receive(:update_attribute).with(:zendesk_id, 42)

        described_class.create_zendesk_user(user)
      end
    end
  end

  describe '#send' do
    context 'support request is valid' do
      before do
        support_request1.stub(valid?: true)
      end

      it 'calls #set_user_zendesk_id if user has no zendesk_id' do
        ZendeskWrapper.should_receive(:create_ticket).with(support_request1.to_params).and_return(ticket)
        manager1.should_receive(:set_user_zendesk_id).with(ticket)

        manager1.send.should be_true
      end
    end

    context 'support request is not valid' do
      before do
        support_request1.stub(valid?: false)
      end

      it 'returns false' do
        ZendeskWrapper.should_not_receive(:create_ticket)
        manager1.should_not_receive(:set_user_zendesk_id)

        manager1.send.should be_false
      end
    end
  end

  describe '#set_user_zendesk_id' do
    it 'sets the zendesk_id of the user' do
      ZendeskWrapper.should_receive(:verify_user)
      support_request1.user.should_receive(:update_attribute).with(:zendesk_id, 12)

      manager1.__send__(:set_user_zendesk_id, ticket)
    end

    it "calls #verify_user on the given ticket" do
      support_request1.user.stub(:update_attribute)
      ZendeskWrapper.should_receive(:verify_user)

      manager1.__send__(:set_user_zendesk_id, ticket)
    end
  end

end
