require 'fast_spec_helper'

stub_module 'ZendeskConfig'

require_relative '../../../../lib/zendesk/zendesk_wrapper'

describe ZendeskWrapper do
  before do
    ZendeskConfig.stub(api_url: 'https://sublimevideo.zendesk.com/api/v1')
    ZendeskConfig.stub(username: 'zendesk@sublimevideo.net')
    ZendeskConfig.stub(api_token: 'oxVzosGyu7DaZrQ0fhmKngHATvd78UhEqTzMszZy')
  end

  let(:params)        { { user_id: 42, type: 'other', subject: 'SUBJECT', message: 'DESCRIPTION' } }
  let(:ticket_params) {
    { subject: 'SUBJECT', description: 'DESCRIPTION', set_tags: ['email-support'],
      requester_name: 'Remy', requester_email: 'user@example.com' }
  }
  let(:requester_id)        { 17650353 }
  let(:ticket_id)           { 2335 }
  let(:ticket_response)     { described_class.ticket(ticket_id) }
  let(:user_response)       { described_class.user(requester_id) }
  let(:raw_search_response) { described_class.send(:get, "/search?query=requester:#{requester_id}") }

  describe '.ticket' do
    use_vcr_cassette 'zendesk_wrapper/ticket'

    it 'returns the wanted ticket' do
      ticket_response.subject.should eq 'SUBJECT'
    end
  end

  describe '.create_ticket' do
    use_vcr_cassette 'zendesk_wrapper/create_ticket'

    it 'returns the created ticket' do
      described_class.create_ticket(ticket_params).subject.should eq 'SUBJECT'
    end
  end

  describe '.user' do
    use_vcr_cassette 'zendesk_wrapper/user'

    it 'returns the user' do
      user_response.email.should eq 'remy@jilion.com'
      user_response.id.should eq 17650353
    end
  end

  describe '.create_user' do
    context 'user has a name' do
      use_vcr_cassette 'zendesk_wrapper/create_user1'
      let(:user) { stub(email: 'user7@example.org', name: 'User Example') }

      it 'creates the user and verifies him' do
        zd_user = described_class.create_user(user)
        zd_user.email.should eq 'user7@example.org'
        zd_user.name.should eq 'User Example'
        zd_user.is_verified.should be_true
      end
    end

    context 'user has no name' do
      use_vcr_cassette 'zendesk_wrapper/create_user2'
      let(:user) { stub(email: 'user8@example.org', name: '') }

      it 'creates the user and verifies him' do
        zd_user = described_class.create_user(user)
        zd_user.email.should eq 'user8@example.org'
        zd_user.name.should eq 'user8@example.org'
        zd_user.is_verified.should be_true
      end
    end
  end

  describe '.update_user' do
    use_vcr_cassette 'zendesk_wrapper/update_user'

    it 'updates the user name' do
      described_class.update_user(requester_id, name: 'John Doe')
      user = described_class.user(requester_id)
      user.name.should eq 'John Doe'
    end

    it 'update the user email and set his last identity as primary' do
      described_class.update_user(requester_id, email: 'user9@example.org')
      identity = described_class.send(:client).users(requester_id).identities.first
      identity.value.should eq 'user9@example.org'
    end
  end

  describe '.search' do
    use_vcr_cassette 'zendesk_wrapper/search'

    it 'returns the wanted tickets' do
      described_class.search(requester: requester_id).should have(1).item
    end
  end

  describe '.verify_user' do
    use_vcr_cassette 'zendesk_wrapper/verify_user'

    it 'verify the user' do
      described_class.verify_user(requester_id).is_verified.should be_true
    end
  end

  describe '.extract_ticket_id_from_location' do
    it 'retrieve a ticket from a full location' do
      location = "https://sublimevideo.zendesk.com/tickets/#{ticket_id}.json"
      described_class.send(:extract_ticket_id_from_location, location).should eq ticket_id
    end
  end

  describe ZendeskWrapper::Ticket do
    use_vcr_cassette 'zendesk_wrapper/ticket/all'
    subject { described_class::Ticket.new(ticket_response) }

    it 'has an id' do
      subject.id.should eq ticket_id
    end

    it 'has a requester_id' do
      subject.requester_id.should eq ticket_response.requester_id
    end

    it 'has a subject' do
      subject.subject.should eq 'SUBJECT'
    end

    it 'has a description' do
      subject.description.should eq 'DESCRIPTION'
    end

    it 'has comments' do
      subject.comments.should have(1).item
    end

    describe '#to_params' do
      it 'returns all params as a hash' do
        subject.to_params.should == {
          id: subject.id,
          requester_id: subject.requester_id,
          subject: subject.subject,
          message: subject.description,
          comments: subject.comments
        }
      end
    end

    describe '#verify_user' do
      it "sets the user as verified on zendesk" do
        described_class.should_receive(:verify_user).with(subject.requester_id)
        subject.verify_user
      end
    end
  end

  describe ZendeskWrapper::Tickets do
    use_vcr_cassette 'zendesk_wrapper/tickets/all'
    subject { described_class::Tickets.new(raw_search_response.body) }

    it 'is an array of Ticket objects' do
      subject.first.requester_id.should eq requester_id
    end
  end

end
