require 'spec_helper'

describe Ticket do
  before do
    @user = create(:user, name: "Remy")
    @site = create(:site, user: @user, plan_id: @paid_plan.id)
    @loser = create(:user)
    create(:site, user: @loser, plan_id: @free_plan.id)
    @vip = create(:user)
    create(:site, user: @vip, plan_id: @custom_plan.token)
  end

  let(:params)         { { user_id: @user.id, type: "other", subject: "SUBJECT", message: "DESCRIPTION" } }
  let(:valid_ticket)   { Ticket.new(params) }
  let(:invalid_ticket) { Ticket.new(params.merge(user_id: nil)) }
  let(:vip_ticket)     { Ticket.new(params.merge(user_id: @vip.id)) }

  describe "Factory" do
    context "without site" do
      subject { valid_ticket }

      its(:subject) { should eq "SUBJECT" }
      its(:message) { should eq "DESCRIPTION" }

      it { should be_valid }
    end

    context "with site" do
      subject { Ticket.new(params.merge(site_token: @site.token)) }

      its(:subject) { should eq "SUBJECT" }
      its(:message) { should eq "Request for site: (#{@site.token}) #{@site.hostname}\n\nDESCRIPTION" }

      it { should be_valid }
    end
  end

  describe "Validations" do
    it "validates presence of user" do
      invalid_ticket.should_not be_valid
      invalid_ticket.should have(1).error_on(:user)
    end

    it "validates presence of subject" do
      ticket = Ticket.new(params.merge(subject: nil))
      ticket.should_not be_valid
      ticket.should have(1).error_on(:subject)
    end

    it "validates presence of message" do
      ticket = Ticket.new(params.merge(message: nil))
      ticket.should_not be_valid
      ticket.should have(1).error_on(:message)
    end

    it "validates user can submit ticket (user without the right)" do
      ticket = Ticket.new(params.merge(user_id: @loser.id))
      ticket.should_not be_valid
      ticket.should have(1).error_on(:base)
    end

    it "validates user can submit ticket (user with the right #1)" do
      valid_ticket.should be_valid
    end

    it "validates user can submit ticket (user with the right #2)" do
      vip_ticket.should be_valid
    end
  end

  describe "Instance Methods" do

    describe "#delay_post" do
      it "delays #post" do
        expect { valid_ticket.delay_post }.to change(Delayed::Job, :count).by(1)
      end

      it "returns true if all is good" do
        valid_ticket.delay_post.should be_true
      end

      it "returns false if not all is good" do
        invalid_ticket.delay_post.should be_false
      end
    end

    describe "#post" do
      it "calls ZendeskWrapper.create_ticket" do
        @ticket = mock('ticket', params: {})
        ZendeskWrapper.should_receive(:create_ticket).with(valid_ticket.to_params).and_return(@ticket)
        valid_ticket.stub(:set_user_zendesk_id)
        valid_ticket.post
      end

      it "calls #set_user_zendesk_id" do
        @ticket = mock('ticket', params: {})
        ZendeskWrapper.stub(:create_ticket).and_return(@ticket)
        valid_ticket.should_receive(:set_user_zendesk_id)
        valid_ticket.post
      end
    end

    describe "#set_user_zendesk_id" do
      it "sets the zendesk_id of the user if he didn't have one already" do
        @user.zendesk_id.should be_nil
        @ticket = mock('ticket', requester_id: 12, params: {}, verify_user: true)
        ZendeskWrapper.should_receive(:create_ticket).and_return(@ticket)
        valid_ticket.post
        @user.reload.zendesk_id.should be_present
      end

      it "calls ZendeskWrapper::Ticket#verify_user" do
        @ticket = mock('ticket', requester_id: 12, params: {})
        ZendeskWrapper.should_receive(:create_ticket).and_return(@ticket)
        @ticket.should_receive(:verify_user)
        valid_ticket.post
      end
    end

    describe "#to_params" do
      context "user has email support" do
        it "generates a hash of the params" do
          valid_ticket.user.support.should eq 'email'
          valid_ticket.to_params.should == {
            subject: 'SUBJECT', description: 'DESCRIPTION', set_tags: ['email-support'],
            requester_name: @user.name, requester_email: @user.email
          }
        end
      end

      context "user has vip support" do
        it "generates a hash of the params" do
          vip_ticket.user.support.should eq 'vip_email'
          vip_ticket.to_params.should == {
            subject: 'SUBJECT', description: 'DESCRIPTION', set_tags: ['vip_email-support'],
            requester_name: @vip.name, requester_email: @vip.email
          }
        end
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
