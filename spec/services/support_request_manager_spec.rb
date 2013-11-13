require 'fast_spec_helper'

require 'wrappers/zendesk_wrapper'
require 'services/support_request_manager'

SupportRequest = Struct.new(:params) unless defined?(SupportRequest)

describe SupportRequestManager do
  let(:user_without_zendesk_id) { double('user', zendesk_id?: false) }
  let(:user_with_zendesk_id)    { double('user', zendesk_id?: true) }
  let(:support_request1)        { double('support_request', to_params: {}, user: user_without_zendesk_id) }
  let(:support_request2)        { double('support_request', to_params: {}, user: user_with_zendesk_id) }
  let(:ticket)                  { double('ticket', requester_id: 12, params: {}) }
  let(:manager1)                { described_class.new(support_request1) }
  let(:manager2)                { described_class.new(support_request2) }

  describe '.create_zendesk_user' do
    context 'user has a zendesk id' do
      let(:user) { double(zendesk_id?: true) }

      it 'does nothing' do
        expect(ZendeskWrapper).not_to receive(:create_user)
        expect(user).not_to receive(:update_attribute)

        described_class.create_zendesk_user(user)
      end
    end

    context 'user has no zendesk id' do
      let(:user) { double(zendesk_id?: false) }

      it 'create a user in Zendesk and set the zendesk_id from it' do
        expect(ZendeskWrapper).to receive(:create_user).with(user).and_return(OpenStruct.new(id: 42))
        expect(user).to receive(:update_attribute).with(:zendesk_id, 42)

        described_class.create_zendesk_user(user)
      end
    end
  end

  describe '#send' do
    context 'support request is valid' do
      before do
        allow(support_request1).to receive(:valid?).and_return(true)
      end

      it 'calls #set_user_zendesk_id if user has no zendesk_id' do
        expect(ZendeskWrapper).to receive(:create_ticket).with(support_request1.to_params).and_return(ticket)
        expect(manager1).to receive(:set_user_zendesk_id).with(ticket)

        expect(manager1.send).to be_truthy
      end
    end

    context 'support request is not valid' do
      before do
        allow(support_request1).to receive(:valid?).and_return(false)
      end

      it 'returns false' do
        expect(ZendeskWrapper).not_to receive(:create_ticket)
        expect(manager1).not_to receive(:set_user_zendesk_id)

        expect(manager1.send).to be_falsey
      end
    end
  end

  describe '#set_user_zendesk_id' do
    it 'sets the zendesk_id of the user' do
      expect(ZendeskWrapper).to receive(:verify_user)
      expect(support_request1.user).to receive(:update_attribute).with(:zendesk_id, 12)

      manager1.__send__(:set_user_zendesk_id, ticket)
    end

    it "calls #verify_user on the given ticket" do
      allow(support_request1.user).to receive(:update_attribute)
      expect(ZendeskWrapper).to receive(:verify_user)

      manager1.__send__(:set_user_zendesk_id, ticket)
    end
  end

end
