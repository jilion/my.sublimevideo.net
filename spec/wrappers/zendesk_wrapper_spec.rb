require 'fast_spec_helper'
require 'support/fixtures_helpers'
require 'config/vcr'

require 'wrappers/zendesk_wrapper'

describe ZendeskWrapper, :vcr do
  let(:ticket_params) {
    { subject: 'SUBJECT', comment: { value: 'DESCRIPTION' }, tags: ['email-support'], requester: { name: 'Remy', email: 'user@example.com' } }
  }
  let(:requester_id)        { 17650353 }
  let(:ticket_id)           { 2335 }
  let(:ticket_response)     { described_class.ticket(ticket_id) }
  let(:user_response)       { described_class.user(requester_id) }

  before { allow(Librato).to receive(:increment) }

  describe '.tickets' do
    it 'returns the wanted ticket' do
      tickets = described_class.tickets.page(1).per_page(100)
      expect(tickets.first).to be_a(ZendeskAPI::Ticket)
    end
  end

  describe '.ticket' do
    it 'returns the wanted ticket' do
      expect(ticket_response.subject).to eq 'SUBJECT'
    end
  end

  describe '.create_ticket' do
    context 'without uploaded files' do
      it 'returns the created ticket' do
        @zd_ticket = described_class.create_ticket(ticket_params)

        @zd_ticket = described_class.ticket(@zd_ticket.id)
        expect(@zd_ticket.description).to eq 'DESCRIPTION'
        expect(@zd_ticket.tags.map(&:name)).to eq ['email-support']
        expect(@zd_ticket.requester.name).to eq 'Remy'
        expect(@zd_ticket.requester.email).to eq 'user@example.com'
      end
    end

    context 'with uploaded files' do
      before do
        @foo = fixture_file('foo.jpg')
        @bar = fixture_file('bar.jpg')
      end

      it 'returns the created ticket' do
        @zd_ticket = described_class.create_ticket(ticket_params.merge(uploads: [@foo, @bar]))
        expect(@zd_ticket.comment[:uploads].map(&:class)).to eq [String, String] # upload was sent as tokens
      end
    end
  end

  describe '.user' do
    it 'returns the user' do
      expect(user_response.email).to eq 'remy@jilion.com'
      expect(user_response.id).to eq 17650353
    end
  end

  describe '.create_user' do
    context 'user has no name' do
      let(:user) { double(id: 1234, email: 'user10@example.org', name_or_email: 'user10@example.org') }
      after { described_class.destroy_user(@zd_user.id) }

      it 'creates the user and verifies him' do
        @zd_user = described_class.create_user(user)
        @zd_user = described_class.user(@zd_user.id)
        expect(@zd_user.external_id).to eq '1234'
        expect(@zd_user.email).to eq 'user10@example.org'
        expect(@zd_user.name).to eq 'user10@example.org'
        expect(@zd_user.verified).to be_truthy
      end
    end

    context 'user has a name' do
      let(:user) { double(id: 1234, email: 'user7@example.org', name_or_email: 'User Example') }
      after { described_class.destroy_user(@zd_user.id) }

      it 'creates the user and verifies him' do
        @zd_user = described_class.create_user(user)
        @zd_user = described_class.user(@zd_user.id)
        expect(@zd_user.external_id).to eq '1234'
        expect(@zd_user.email).to eq 'user7@example.org'
        expect(@zd_user.name).to eq 'User Example'
        expect(@zd_user.verified).to be_truthy
      end
    end
  end

  describe '.update_user' do

    describe 'update name' do
      let(:user) { double(id: 4321, email: '1231231231231@example.org', name_or_email: 'Remy Coutable') }
      before { @zd_user = described_class.create_user(user) }
      after { described_class.destroy_user(@zd_user.id) }

      it 'updates the user name' do
        described_class.update_user(@zd_user.id, name: 'John Doe')
        expect(described_class.user(@zd_user.id).name).to eq 'John Doe'
      end
    end

    describe 'update email' do
      let(:user) { double(id: 3210, email: '321321321@example.org', name_or_email: 'Remy Coutable') }
      before { @zd_user = described_class.create_user(user) }
      after { described_class.destroy_user(@zd_user.id) }

      it 'update the user email and set his last identity as primary' do
        described_class.update_user(@zd_user.id, email: 'user43210@example.org')

        identity = described_class.user(@zd_user.id).identities.first
        expect(identity.value).to eq 'user43210@example.org'
        expect(identity.verified).to be_truthy
        expect(identity.primary).to be_truthy
      end
    end
  end

  describe '.destroy_user' do
    context 'user has a name' do
      let(:user) { double(id: 1234, email: 'user1234@example.org', name_or_email: 'User Example') }
      before { @zd_user = described_class.create_user(user) }

      it 'creates the user and verifies him' do
        described_class.destroy_user(@zd_user.id)

        expect(described_class.user(@zd_user.id).active).to be_falsey
      end
    end
  end

  describe '.search' do
    it 'returns the wanted tickets' do
      expect(described_class.search(query: "requester_id:#{requester_id}").size).to eq(6)
    end
  end

  describe '.verify_user' do
    it 'verify the user' do
      described_class.verify_user(requester_id)

      expect(described_class.user(requester_id).verified).to be_truthy
    end
  end

  describe '.extract_ticket_id_from_location' do
    it 'retrieve a ticket from a full location' do
      location = "https://sublimevideo.zendesk.com/tickets/#{ticket_id}.json"
      expect(described_class.send(:extract_ticket_id_from_location, location)).to eq ticket_id
    end
  end
end
