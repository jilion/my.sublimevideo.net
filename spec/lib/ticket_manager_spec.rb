require 'fast_spec_helper'
require 'active_support/concern'
require File.expand_path('lib/ticket_manager')

describe TicketManager do

  let(:params)                  { { user_id: 42, type: 'other', subject: 'SUBJECT', message: 'DESCRIPTION' } }
  let(:user_without_zendesk_id) { mock('user', zendesk_id?: false) }
  let(:user_with_zendesk_id)    { mock('user', zendesk_id?: true) }
  let(:support_request1)        { mock('support_request', to_params: {}, user: user_without_zendesk_id) }
  let(:support_request2)        { mock('support_request', to_params: {}, user: user_with_zendesk_id) }
  let(:ticket)                  { mock('ticket', requester_id: 12, params: {}) }

  describe '.create' do
    it 'calls #set_user_zendesk_id if user has no zendesk_id' do
      ZendeskWrapper.stub(:create_ticket).with(support_request1.to_params).and_return(ticket)
      described_class.should_receive(:set_user_zendesk_id).with(ticket, support_request1.user)

      described_class.create(support_request1)
    end

    it 'calls #set_user_zendesk_id if user has a zendesk_id' do
      ZendeskWrapper.stub(:create_ticket).with(support_request2.to_params)
      described_class.should_not_receive(:set_user_zendesk_id)

      described_class.create(support_request2)
    end
  end

  describe '.set_user_zendesk_id' do
    it 'sets the zendesk_id of the user' do
      ticket.stub(:verify_user)
      support_request1.user.should_receive(:update_attribute).with(:zendesk_id, 12)

      described_class.set_user_zendesk_id(ticket, support_request1.user)
    end

    it "calls #verify_user on the given ticket" do
      support_request1.user.stub(:update_attribute)
      ticket.should_receive(:verify_user)

      described_class.set_user_zendesk_id(ticket, support_request1.user)
    end
  end

end
