require 'fast_spec_helper'

require 'services/user_support_manager'
require 'models/support_request'

User = Class.new unless defined? User
Site = Class.new unless defined? Site

describe SupportRequest do

  let(:user_without_zendesk_id) { stub(:user, id: 1, name_or_email: 'Remy', email: 'remy@rymai.me', zendesk_id?: false) }
  let(:user_with_zendesk_id)    { stub(:user, id: 2, name_or_email: 'Remy', email: 'remy@rymai.me', zendesk_id?: true, zendesk_id: 1234) }
  let(:user_without_name)       { stub(:user, id: 3, name_or_email: 'remy@rymai.me', email: 'remy@rymai.me', zendesk_id?: false) }
  let(:site)                    { stub(:site, token: 'abcd1234', hostname: 'rymai.me', user: user_without_zendesk_id) }
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
  let(:support_request_with_stage)      { described_class.new(params.merge(stage: 'beta')) }
  before do
    User.stub(:find_by_id).with(1) { user_without_zendesk_id }
    User.stub(:find_by_id).with(2) { user_with_zendesk_id }
    User.stub(:find_by_id).with(3) { user_without_name }
    User.stub(:find_by_id).with(nil) { nil }
    Site.stub(:find_by_token).with('abcd1234') { site }
    Site.stub(:find_by_token).with(nil) { nil }
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
      its(:comment) { should eq "Request for site: (#{site.token}) #{site.hostname}\nPlayer version: N/A\nThe issue occurs on this page: http://example.org\nThe issue occurs under this environment: Windows\n\nDESCRIPTION" }

      it { should be_valid }
    end
  end

  describe 'Validations' do
    it 'validates presence of user' do
      support_request = described_class.new(params.merge(user_id: nil))
      support_request.should_not be_valid
      support_request.should have(1).error_on(:user)
    end

    it 'validates presence of subject' do
      support_request = described_class.new(params.merge(subject: nil))
      support_request.should_not be_valid
      support_request.should have(1).error_on(:subject)
    end

    it 'validates presence of message' do
      support_request = described_class.new(params.merge(message: nil))
      support_request.should_not be_valid
      support_request.should have(1).error_on(:message)
    end
  end

  describe '#to_params' do
    context 'user has email support' do
      before do
        UserSupportManager.should_receive(:new) { stub(level: 'email') }
      end

      context 'player stage is specified' do
        it 'generates a hash of the params' do
          support_request_with_stage.to_params.should == {
            subject: 'SUBJECT', comment: { value: "Player version: beta\nThe issue occurs on this page: http://example.org\nThe issue occurs under this environment: Windows\n\nDESCRIPTION" },
            tags: ['email-support', 'stage-beta'], requester: { name: user_without_zendesk_id.name_or_email, email: user_without_zendesk_id.email }, uploads: ['foo.jpg', 'bar.html'], external_id: user_without_zendesk_id.id
          }
        end
      end

      context 'user has no name' do
        it 'generates a hash of the params' do
          support_request_without_name.user.name_or_email.should eq support_request_without_name.user.email
          support_request_without_name.to_params.should == {
            subject: 'SUBJECT', comment: { value: "Player version: N/A\nThe issue occurs on this page: http://example.org\nThe issue occurs under this environment: Windows\n\nDESCRIPTION" },
            tags: ['email-support'], requester: { name: user_without_name.email, email: user_without_name.email }, uploads: ['foo.jpg', 'bar.html'], external_id: user_without_name.id
          }
        end
      end
    end

    context 'user has vip support' do
      before do
        UserSupportManager.should_receive(:new) { stub(level: 'vip_email') }
      end

      it 'generates a hash of the params' do
        vip_support_request.to_params.should == {
          subject: 'SUBJECT', comment: { value: "Player version: N/A\nThe issue occurs on this page: http://example.org\nThe issue occurs under this environment: Windows\n\nDESCRIPTION" },
          tags: ['vip_email-support'], requester: { name: user_without_zendesk_id.name_or_email, email: user_without_zendesk_id.email },
          uploads: ['foo.jpg', 'bar.html'], external_id: user_without_zendesk_id.id
        }
      end
    end

    context 'user has a zendesk id' do
      before do
        UserSupportManager.should_receive(:new) { stub(level: 'email') }
      end

      it 'generates a hash of the params' do
        support_request_with_zendesk_id.to_params.should == {
          subject: 'SUBJECT', comment: { value: "Player version: N/A\nThe issue occurs on this page: http://example.org\nThe issue occurs under this environment: Windows\n\nDESCRIPTION" }, tags: ['email-support'],
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
