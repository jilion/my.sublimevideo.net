require 'spec_helper'

describe SupportRequest, :plans do
  before do
    @user  = create(:user, name: 'Remy')
    @user2 = create(:user, name: 'Remy', zendesk_id: 1234)
    @user3 = create(:user, name: '')
    @site  = create(:site, user: @user, plan_id: @paid_plan.id)
    create(:site, user: @user2, plan_id: @paid_plan.id)
    create(:site, user: @user3, plan_id: @paid_plan.id)
    @loser = create(:user)
    create(:site, user: @loser, plan_id: @free_plan.id)
    @vip = create(:user)
    create(:site, user: @vip, plan_id: @custom_plan.token)
  end

  let(:params) {
    {
      user_id: @user.id, type: 'other', subject: 'SUBJECT', message: 'DESCRIPTION',
      env: 'Windows', test_page: 'http://example.org', uploads: ['foo.jpg', 'bar.html']
    }
  }
  let(:support_request)                 { described_class.new(params) }
  let(:support_request_without_name)    { described_class.new(params.merge(user_id: @user3.id)) }
  let(:support_request_with_zendesk_id) { described_class.new(params.merge(user_id: @user2.id)) }
  let(:invalid_support_request)         { described_class.new(params.merge(user_id: '')) }
  let(:vip_support_request)             { described_class.new(params.merge(user_id: @vip.id)) }

  describe 'Factory' do
    context 'without site' do
      subject { support_request }

      its(:subject) { should eq 'SUBJECT' }
      its(:message) { should =~ /DESCRIPTION/ }

      it { should be_valid }
    end

    context 'with site' do
      subject { described_class.new(params.merge(site_token: @site.token)) }

      its(:subject) { should eq 'SUBJECT' }
      its(:message) { should eq "DESCRIPTION" }
      its(:comment) { should eq "Request for site: (#{@site.token}) #{@site.hostname} (in #{@site.plan.title} plan)\nThe issue occurs on this page: http://example.org\nThe issue occurs under this environment: Windows\n\nDESCRIPTION" }

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

    it 'validates user can submit support request (user without the right)' do
      support_request = described_class.new(params.merge(user_id: @loser.id))
      support_request.should_not be_valid
      support_request.should have(1).error_on(:base)
    end

    it 'validates user can submit support request (user with the right #1)' do
      support_request.should be_valid
    end

    it 'validates user can submit support request (user with the right #2)' do
      vip_support_request.should be_valid
    end
  end

  describe '#post' do
    it "calls TicketManager.create" do
      TicketManager.should_receive(:create).with(support_request).and_return(true)

      support_request.post.should be_true
    end
  end

  describe '#to_params' do
    context 'user has no name' do
      it 'generates a hash of the params' do
        support_request_without_name.user.name.should eq ''
        support_request_without_name.to_params.should == {
          subject: 'SUBJECT', comment: { value: "The issue occurs on this page: http://example.org\nThe issue occurs under this environment: Windows\n\nDESCRIPTION" }, tags: ['email-support'],
          requester: { name: @user3.email, email: @user3.email }, uploads: ['foo.jpg', 'bar.html'], external_id: @user3.id
        }
      end
    end

    context 'user has email support' do
      it 'generates a hash of the params' do
        support_request.user.support.should eq 'email'
        support_request.to_params.should == {
          subject: 'SUBJECT', comment: { value: "The issue occurs on this page: http://example.org\nThe issue occurs under this environment: Windows\n\nDESCRIPTION" }, tags: ['email-support'],
          requester: { name: @user.name, email: @user.email }, uploads: ['foo.jpg', 'bar.html'], external_id: @user.id
        }
      end
    end

    context 'user has vip support' do
      it 'generates a hash of the params' do
        vip_support_request.user.support.should eq 'vip_email'
        vip_support_request.to_params.should == {
          subject: 'SUBJECT', comment: { value: "The issue occurs on this page: http://example.org\nThe issue occurs under this environment: Windows\n\nDESCRIPTION" }, tags: ['vip_email-support'],
          requester: { name: @vip.name, email: @vip.email }, uploads: ['foo.jpg', 'bar.html'], external_id: @vip.id
        }
      end
    end

    context 'user has a zendesk id' do
      it 'generates a hash of the params' do
        support_request_with_zendesk_id.to_params.should == {
          subject: 'SUBJECT', comment: { value: "The issue occurs on this page: http://example.org\nThe issue occurs under this environment: Windows\n\nDESCRIPTION" }, tags: ['email-support'],
          requester_id: @user2.zendesk_id, uploads: ['foo.jpg', 'bar.html'], external_id: @user2.id
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
