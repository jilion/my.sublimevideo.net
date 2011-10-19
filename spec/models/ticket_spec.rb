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
    @user = FactoryGirl.create(:user, first_name: "Remy")
    @site = FactoryGirl.create(:site, user: @user, plan_id: @paid_plan.id)
    @loser = FactoryGirl.create(:user)
    FactoryGirl.create(:site, user: @loser, plan_id: @free_plan.id)
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

    it "validates ticket type submission allowed" do
      ticket = Ticket.new({ user_id: @loser.id, type: "integration", subject: "Subject", message: "Message" })
      ticket.should_not be_valid
      ticket.should have(1).error_on(:base)
    end
  end

  describe "Class Methods" do

    describe ".post_ticket" do
      describe "common behavior" do
         let(:ticket) { Ticket.new({ user_id: @user.reload.id, type: "idea", subject: "I have a request!", message: "I have a request this is a long text!" }) }
        use_vcr_cassette "ticket/post_ticket"

        it "creates the ticket on Zendesk" do
          zendesk_tickets_count_before_post = VCR.use_cassette("ticket/zendesk_tickets_before_post") do
            JSON[Zendesk.get("/rules/1614956.json").body].size
          end
          Ticket.post_ticket(ticket)
          VCR.use_cassette("ticket/zendesk_tickets_after_post") do
            JSON[Zendesk.get("/rules/1614956.json").body].size.should == zendesk_tickets_count_before_post + 1
          end
        end

        it "sets the subject for the ticket based on its subject" do
          JSON[Zendesk.get("/tickets/#{Ticket.post_ticket(ticket)}.json").body]["subject"].should == ticket.subject
        end

        it "sets the message for the ticket based on its message" do
          JSON[Zendesk.get("/tickets/#{Ticket.post_ticket(ticket)}.json").body]["description"].should == ticket.message
        end

        it "sets the zendesk_id of the user if he didn't have one already" do
          ticket.user.zendesk_id.should be_nil
          Ticket.post_ticket(ticket)
          ticket.user.reload.zendesk_id.should be_present
        end

        it "delays Ticket#verify_user" do
          Ticket.post_ticket(ticket)
          Delayed::Job.last.name.should == 'Class#verify_user'
        end
      end
    end

    describe ".verify_user" do
      let(:ticket) { Ticket.new({ user_id: @user.reload.id, type: "idea", subject: "I have a request!", message: "I have a request this is a long text!" }) }

      it "sets the user as verified on zendesk" do
        VCR.use_cassette("ticket/post_ticket") { Ticket.post_ticket(ticket) }
        VCR.use_cassette("ticket/verify_user") do
          Ticket.verify_user(@user.id)
          JSON[Zendesk.get("/users/#{ticket.user.reload.zendesk_id}.json").body]["is_verified"].should be_true
        end
      end
    end
  end

  describe "Instance Methods" do
    let(:ticket) { Ticket.new({ user_id: @user.reload.id, type: "other", subject: "I have a request!", message: "I have a request this is a long text!" }) }

    describe "#save" do
      it "delays Ticket.post_ticket" do
        ticket.save
        Delayed::Job.last.name.should eql "Delayed::PerformableMethod"
      end

      it "returns true if all is good" do
        ticket.save.should be_true
      end

      it "returns false if not all is good" do
        ticket.user = nil
        ticket.save.should be_false
      end
    end

    describe "#to_xml" do
      context "user has email support" do
        it "generates a xml" do
          ticket.to_xml.should eql <<-EOF
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
        before { ticket.user.stub(:support) { 'vip' } }

        it "generates a xml" do
          ticket.user.support.should eql 'vip'
          ticket.to_xml.should eql <<-EOF
<ticket>
  <subject>I have a request!</subject>
  <description>I have a request this is a long text!</description>
  <set-tags>vip</set-tags>
  <requester-name>#{@user.full_name}</requester-name>
  <requester-email>#{@user.email}</requester-email>
</ticket>
EOF
        end
      end
    end

  end

end
