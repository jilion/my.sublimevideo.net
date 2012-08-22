require 'fast_spec_helper'
require 'support/fixtures_helpers'
require File.expand_path('spec/config/vcr')
require File.expand_path('lib/zendesk_wrapper')

describe ZendeskWrapper do
  let(:ticket_params) {
    { subject: 'SUBJECT', comment: { value: 'DESCRIPTION' }, tags: ['email-support'], requester: { name: 'Remy', email: 'user@example.com' }
    }
  }
  let(:requester_id)        { 17650353 }
  let(:ticket_id)           { 2335 }
  let(:ticket_response)     { described_class.ticket(ticket_id) }
  let(:user_response)       { described_class.user(requester_id) }

  describe '.tickets' do
    use_vcr_cassette 'zendesk_wrapper/tickets'

    it 'returns the wanted ticket' do
      tickets = described_class.tickets.page(1).per_page(100)
      tickets.first.should be_a(ZendeskAPI::Ticket)
    end
  end

  describe '.ticket' do
    use_vcr_cassette 'zendesk_wrapper/ticket'

    it 'returns the wanted ticket' do
      ticket_response.subject.should eq 'SUBJECT'
    end
  end

  describe '.create_ticket' do
    context 'without uploaded files' do
      use_vcr_cassette 'zendesk_wrapper/create_ticket'

      it 'returns the created ticket' do
        @zd_ticket = described_class.create_ticket(ticket_params)

        @zd_ticket = described_class.ticket(@zd_ticket.id)
        @zd_ticket.description.should eq 'DESCRIPTION'
        @zd_ticket.tags.should eq ['email-support']
        @zd_ticket.requester.name.should eq 'Remy'
        @zd_ticket.requester.email.should eq 'user@example.com'
      end
    end

    context 'with uploaded files' do
      use_vcr_cassette 'zendesk_wrapper/create_ticket_with_uploaded_files'

      it 'returns the created ticket' do
        @zd_ticket = described_class.create_ticket(ticket_params.merge(uploads: [fixture_file('license.js').path, fixture_file('quicktime_sample.mov').path]))
        @zd_ticket.comment[:uploads].map(&:class).should eq [String, String] # upload was sent as tokens
      end
    end
  end

  describe '.user' do
    use_vcr_cassette 'zendesk_wrapper/user'

    it 'returns the user' do
      puts user_response.inpect
      user_response.email.should eq 'remy@jilion.com'
      user_response.id.should eq 17650353
    end
  end

  describe '.create_user' do
    context 'user has a name' do
      use_vcr_cassette 'zendesk_wrapper/create_user'
      let(:user) { stub(id: 1234, email: 'user7@example.org', name: 'User Example') }

      after { described_class.destroy_user(@zd_user.id) }

      it 'creates the user and verifies him' do
        @zd_user = described_class.create_user(user)
        @zd_user = described_class.user(@zd_user.id)
        @zd_user.external_id.should eq '1234'
        @zd_user.email.should eq 'user7@example.org'
        @zd_user.name.should eq 'User Example'
        @zd_user.verified.should be_true
      end
    end
  end

  describe '.update_user' do


    describe 'update name' do
      let(:user) { stub(id: 4321, email: '1231231231231@example.org', name: 'Remy Coutable') }
      before { VCR.use_cassette('zendesk_wrapper/reset_user') { @zd_user = described_class.create_user(user) } }
      after { VCR.use_cassette('zendesk_wrapper/reset_user') { described_class.destroy_user(@zd_user.id) } }
      use_vcr_cassette 'zendesk_wrapper/update_user_name'

      it 'updates the user name' do
        described_class.update_user(@zd_user.id, name: 'John Doe')

        described_class.user(@zd_user.id).name.should eq 'John Doe'
      end
    end

    describe 'update email' do
      let(:user) { stub(id: 3210, email: '321321321@example.org', name: 'Remy Coutable') }
      before { VCR.use_cassette('zendesk_wrapper/reset_user2') { @zd_user = described_class.create_user(user) } }
      after { VCR.use_cassette('zendesk_wrapper/reset_user2') { described_class.destroy_user(@zd_user.id) } }
      use_vcr_cassette 'zendesk_wrapper/update_user_email'

      it 'update the user email and set his last identity as primary' do
        described_class.update_user(@zd_user.id, email: 'user43210@example.org')

        identity = described_class.user(@zd_user.id).identities.first
        identity.value.should eq 'user43210@example.org'
        identity.verified.should be_true
        identity.primary.should be_true
      end
    end
  end

  describe '.destroy_user' do
    context 'user has a name' do
      use_vcr_cassette 'zendesk_wrapper/destroy_user'
      let(:user) { stub(id: 1234, email: 'user1234@example.org', name: 'User Example') }

      before { @zd_user = described_class.create_user(user) }

      it 'creates the user and verifies him' do
        described_class.destroy_user(@zd_user.id)

        described_class.user(@zd_user.id).active.should be_false
      end
    end
  end

  describe '.search' do
    use_vcr_cassette 'zendesk_wrapper/search'

    it 'returns the wanted tickets' do
      described_class.search(query: "requester_id:#{requester_id}").should have(1).item
    end
  end

  describe '.verify_user' do
    use_vcr_cassette 'zendesk_wrapper/verify_user'

    it 'verify the user' do
      described_class.verify_user(requester_id)

      described_class.user(requester_id).verified.should be_true
    end
  end

  describe '.extract_ticket_id_from_location' do
    it 'retrieve a ticket from a full location' do
      location = "https://sublimevideo.zendesk.com/tickets/#{ticket_id}.json"
      described_class.send(:extract_ticket_id_from_location, location).should eq ticket_id
    end
  end

end
