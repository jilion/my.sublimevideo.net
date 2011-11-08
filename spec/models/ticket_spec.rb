# == Schema Information
#
#  type            :integer   not null
#  subject         :string    not null
#  message         :text      not null
#  requester_name  :string
#  requester_email :string
#
#

require 'spec_helper'

describe Ticket do
  before(:all) do
    @user = Factory.create(:user, first_name: "Remy")
    @site = Factory.create(:site, user: @user, plan_id: @paid_plan.id)
    @loser = Factory.create(:user)
    Factory.create(:site, user: @loser, plan_id: @free_plan.id)
    @vip = Factory.create(:user)
    Factory.create(:site, user: @vip, plan_id: @custom_plan.token)
  end

  describe "Factory" do
    context "without site" do
      before(:all) do
        @ticket = Ticket.new({ user_id: @user.id, subject: "Subject", message: "Message" })
      end
      subject { @ticket }

      its(:subject) { should eql "Subject" }
      its(:message) { should eql "Message" }

      it { should be_valid }
    end

    context "with site" do
      before(:all) do
        @ticket = Ticket.new({ user_id: @user.id, site_token: @site.token, subject: "Subject", message: "Message" })
      end
      subject { @ticket }

      its(:subject) { should eql "Subject" }
      its(:message) { should eql "Request for site: (#{@site.token}) #{@site.hostname}\n\nMessage" }

      it { should be_valid }
    end
  end

  describe "Validations" do
    it "validates presence of user" do
      ticket = Ticket.new({ user_id: nil, type: "integration", subject: nil, message: "Message" })
      ticket.should_not be_valid
      ticket.should have(1).error_on(:user)
    end

    it "validates presence of subject" do
      ticket = Ticket.new({ user_id: @user.id, type: "idea", subject: nil, message: "Message" })
      ticket.should_not be_valid
      ticket.should have(1).error_on(:subject)
    end

    it "validates presence of message" do
      ticket = Ticket.new({ user_id: @user.id, type: "billing", subject: "Subject", message: nil })
      ticket.should_not be_valid
      ticket.should have(1).error_on(:message)
    end

    it "validates user can submit ticket (user without the right)" do
      ticket = Ticket.new({ user_id: @loser.id, type: "integration", subject: "Subject", message: "Message" })
      ticket.should_not be_valid
      ticket.should have(1).error_on(:base)
    end

    it "validates user can submit ticket (user with the right #1)" do
      ticket = Ticket.new({ user_id: @user.id, type: "integration", subject: "Subject", message: "Message" })
      ticket.should be_valid
    end

    it "validates user can submit ticket (user with the right #2)" do
      ticket = Ticket.new({ user_id: @vip.id, type: "integration", subject: "Subject", message: "Message" })
      ticket.should be_valid
    end
  end

  describe "Class Methods" do

    describe ".post_ticket" do
      describe "common behavior" do
         let(:params) { { user_id: @user.reload.id, type: "idea", subject: "I have a request!", message: "I have a request this is a long text!" } }
        use_vcr_cassette "ticket/post_ticket"

        it "creates the ticket on Zendesk" do
          zendesk_tickets_count_before_post = VCR.use_cassette("ticket/zendesk_tickets_before_post") do
            JSON[Zendesk.get("/rules/1614956.json").body].size
          end
          Ticket.post_ticket(params)
          VCR.use_cassette("ticket/zendesk_tickets_after_post") do
            JSON[Zendesk.get("/rules/1614956.json").body].size.should eq zendesk_tickets_count_before_post + 1
          end
        end

        it "sets the subject for the ticket based on its subject" do
          JSON[Zendesk.get("/tickets/#{Ticket.post_ticket(params)}.json").body]["subject"].should eq params[:subject]
        end

        it "sets the message for the ticket based on its message" do
          JSON[Zendesk.get("/tickets/#{Ticket.post_ticket(params)}.json").body]["description"].should eq params[:message]
        end

        it "sets the zendesk_id of the user if he didn't have one already" do
          @user.zendesk_id.should be_nil
          Ticket.post_ticket(params)
          @user.reload.zendesk_id.should be_present
        end

        it "delays Ticket#verify_user" do
          Ticket.post_ticket(params)
          Delayed::Job.last.name.should eq 'Class#verify_user'
        end
      end
    end

    describe ".verify_user" do
      let(:params) { { user_id: @user.reload.id, type: "idea", subject: "I have a request!", message: "I have a request this is a long text!" } }

      it "sets the user as verified on zendesk" do
        VCR.use_cassette("ticket/post_ticket") { Ticket.post_ticket(params) }
        VCR.use_cassette("ticket/verify_user") do
          Ticket.verify_user(@user.id)
          JSON[Zendesk.get("/users/#{@user.reload.zendesk_id}.json").body]["is_verified"].should be_true
        end
      end
    end
  end

  describe "Instance Methods" do
    let(:valid_ticket) { Ticket.new({ user_id: @user.id, type: "other", subject: "I have a request!", message: "I have a request this is a long text!" }) }
    let(:invalid_ticket) { Ticket.new({ user_id: nil, type: "other", subject: "I have a request!", message: "I have a request this is a long text!" }) }
    let(:vip_ticket) { Ticket.new({ user_id: @vip.id, type: "other", subject: "I have a request!", message: "I have a request this is a long text!" }) }

    describe "#save" do
      it "delays Ticket.post_ticket" do
        valid_ticket.save
        Delayed::Job.last.name.should eql "Class#post_ticket"
      end

      it "returns true if all is good" do
        valid_ticket.save.should be_true
      end

      it "returns false if not all is good" do
        invalid_ticket.save.should be_false
      end
    end

    describe "#to_xml" do
      context "user has email support" do
        it "generates a xml" do
          valid_ticket.to_xml.should eq <<-EOF
<ticket>
  <subject>I have a request!</subject>
  <description>I have a request this is a long text!</description>
  <requester-name>#{@user.full_name}</requester-name>
  <requester-email>#{@user.email}</requester-email>
</ticket>
EOF
        end
      end

      context "user has vip support" do
        it "generates a xml" do
          vip_ticket.user.support.should eql 'vip'
          vip_ticket.to_xml.should eql <<-EOF
<ticket>
  <subject>I have a request!</subject>
  <description>I have a request this is a long text!</description>
  <set-tags>vip</set-tags>
  <requester-name>#{@vip.full_name}</requester-name>
  <requester-email>#{@vip.email}</requester-email>
</ticket>
EOF
        end
      end
    end

  end

end
