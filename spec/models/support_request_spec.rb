require 'fast_spec_helper'

require 'services/user_support_manager'
require 'models/support_request' unless defined?(SupportRequest)

User = Class.new unless defined? User
Site = Class.new unless defined? Site

describe SupportRequest do

  let(:user_without_zendesk_id) { double(:user, id: 1, name_or_email: 'Remy', email: 'remy@rymai.me', zendesk_id?: false) }
  let(:user_with_zendesk_id)    { double(:user, id: 2, name_or_email: 'Remy', email: 'remy@rymai.me', zendesk_id?: true, zendesk_id: 1234) }
  let(:user_without_name)       { double(:user, id: 3, name_or_email: 'remy@rymai.me', email: 'remy@rymai.me', zendesk_id?: false) }
  let(:site)                    { double(:site, token: 'abcd1234', hostname: 'rymai.me', user: user_without_zendesk_id) }
  let(:params) {
    {
      user_id: user_without_zendesk_id.id, type: 'other', subject: 'SUBJECT', message: 'DESCRIPTION',
      env: 'Windows', test_page: 'http://example.org', uploads: ['foo.jpg', 'bar.html']
    }
  }
  let(:support_request)                 { described_class.new(params) }
  let(:support_request_with_zendesk_id) { described_class.new(params.merge(user_id: user_with_zendesk_id.id)) }
  let(:invalid_support_request)         { described_class.new(params.merge(user_id: nil)) }
  let(:vip_support_request)             { described_class.new(params.merge(user_id: user_without_zendesk_id.id)) }
  let(:support_request_without_name)    { described_class.new(params.merge(user_id: user_without_name.id)) }
  before do
    User.stub(:where).with(id: 1) { double(first: user_without_zendesk_id) }
    User.stub(:where).with(id: 2) { double(first: user_with_zendesk_id) }
    User.stub(:where).with(id: 3) { double(first: user_without_name) }
    User.stub(:where).with(id: nil) { double(first: nil) }
    Site.stub(:where).with(token: 'abcd1234') { double(first: site) }
    Site.stub(:where).with(token: nil) { double(first: nil) }
  end

  describe 'Factory' do
    context 'without site' do
      subject { support_request }

      its(:subject) { should eq 'SUBJECT' }
      its(:message) { should =~ /DESCRIPTION/ }

      it { should be_valid }
    end

    context 'with site' do
      subject { described_class.new(params.merge(site_token: site.token)) }

      its(:subject) { should eq 'SUBJECT' }
      its(:message) { should eq "DESCRIPTION" }
      its(:comment) { should eq "Request for site: (#{site.token}) #{site.hostname}\nThe issue occurs on this page: http://example.org\nThe issue occurs under this environment: Windows\n\nDESCRIPTION" }

      it { should be_valid }
    end
  end

  describe 'Validations' do
    it 'validates presence of user' do
      support_request = described_class.new(params.merge(user_id: nil))

      expect(support_request).to_not be_valid
      expect(support_request.errors[:user]).to have(1).item
    end

    it 'validates presence of subject' do
      support_request = described_class.new(params.merge(subject: nil))

      expect(support_request).to_not be_valid
      expect(support_request.errors[:subject]).to have(1).item
    end

    it 'validates presence of message' do
      support_request = described_class.new(params.merge(message: nil))

      expect(support_request).to_not be_valid
      expect(support_request.errors[:message]).to have(1).item
    end
  end

  describe '#to_params' do
    context 'user has email support' do
      before do
        UserSupportManager.should_receive(:new) { double(level: 'email') }
      end

      context 'user has no name' do
        it 'generates a hash of the params' do
          support_request_without_name.user.name_or_email.should eq support_request_without_name.user.email
          support_request_without_name.to_params.should == {
            subject: 'SUBJECT', comment: { value: "The issue occurs on this page: http://example.org\nThe issue occurs under this environment: Windows\n\nDESCRIPTION" },
            tags: ['email-support'], requester: { name: user_without_name.email, email: user_without_name.email }, uploads: ['foo.jpg', 'bar.html'], external_id: user_without_name.id
          }
        end
      end
    end

    context 'user has vip support' do
      before do
        UserSupportManager.should_receive(:new) { double(level: 'vip_email') }
      end

      it 'generates a hash of the params' do
        vip_support_request.to_params.should == {
          subject: 'SUBJECT', comment: { value: "The issue occurs on this page: http://example.org\nThe issue occurs under this environment: Windows\n\nDESCRIPTION" },
          tags: ['vip_email-support'], requester: { name: user_without_zendesk_id.name_or_email, email: user_without_zendesk_id.email },
          uploads: ['foo.jpg', 'bar.html'], external_id: user_without_zendesk_id.id
        }
      end
    end

    context 'user has a zendesk id' do
      before do
        UserSupportManager.should_receive(:new) { double(level: 'email') }
      end

      it 'generates a hash of the params' do
        support_request_with_zendesk_id.to_params.should == {
          subject: 'SUBJECT', comment: { value: "The issue occurs on this page: http://example.org\nThe issue occurs under this environment: Windows\n\nDESCRIPTION" }, tags: ['email-support'],
          tags: ['email-support'], requester_id: user_with_zendesk_id.zendesk_id, uploads: ['foo.jpg', 'bar.html'], external_id: user_with_zendesk_id.id
        }
      end
    end
  end

end
# == Schema Information
#
#  type            :integer   not null
#  subject         :string    not null
#  message         :text      not null
#  requester_name  :string
#  requester_email :string
#
#
#
