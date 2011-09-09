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
    FactoryGirl.create(:site, user: @user, plan_id: @paid_plan.id)
    @loser = FactoryGirl.create(:user)
    FactoryGirl.create(:site, user: @loser, plan_id: @free_plan.id)
  end

  describe "Factory" do
    before(:all) do
      @ticket = Ticket.new({ user_id: @user.id, type: "bug", subject: "Subject", message: "Message" })
    end
    subject { @ticket }

    its(:type)    { should == "bug" }
    its(:subject) { should == "Subject" }
    its(:message) { should == "Message" }

    it { should be_valid }
  end

  describe "Validations" do
    Ticket::TYPES.each do |type|
      it { should allow_value(type).for(:type) }
    end

    %w[foo bar test].each do |type|
      it { should_not allow_value(type).for(:type) }
    end

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

        it "should create the ticket on Zendesk" do
          zendesk_tickets_count_before_post = VCR.use_cassette("ticket/zendesk_tickets_before_post") do
            JSON[Zendesk.get("/rules/1614956.json").body].size
          end
          Ticket.post_ticket(ticket.to_hash)
          VCR.use_cassette("ticket/zendesk_tickets_after_post") do
            JSON[Zendesk.get("/rules/1614956.json").body].size.should == zendesk_tickets_count_before_post + 1
          end
        end

        it "should set the subject for the ticket based on its subject" do
          JSON[Zendesk.get("/tickets/#{Ticket.post_ticket(ticket.to_hash)}.json").body]["subject"].should == ticket.subject
        end

        it "should set the message for the ticket based on its message" do
          JSON[Zendesk.get("/tickets/#{Ticket.post_ticket(ticket.to_hash)}.json").body]["description"].should == ticket.message
        end

        it "should set the zendesk_id of the user if he didn't have one already" do
          ticket.user.zendesk_id.should be_nil
          Ticket.post_ticket(ticket.to_hash)
          ticket.user.reload.zendesk_id.should be_present
        end

        it "should delay Ticket#verify_user" do
          Ticket.post_ticket(ticket.to_hash)
          Delayed::Job.last.name.should == 'Class#verify_user'
        end
      end
    end

    describe ".verify_user" do
      let(:ticket) { Ticket.new({ user_id: @user.reload.id, type: "idea", subject: "I have a request!", message: "I have a request this is a long text!" }) }

      it "should set the user as verified on zendesk" do
        VCR.use_cassette("ticket/post_ticket") { Ticket.post_ticket(ticket.to_hash) }
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
      it "should delay Ticket.post_ticket" do
        ticket.save
        Delayed::Job.last.name.should eql "Class#post_ticket"
      end
      it "should return true if all is good" do
        ticket.save.should be_true
      end
      it "should return false if not all is good" do
        ticket.user = nil
        ticket.save.should be_false
      end
    end

    describe "#to_xml" do
      it "generates a xml" do
        ticket.to_xml.should == <<-EOF
<ticket>
  <subject>I have a request!</subject>
  <description>I have a request this is a long text!</description>
  <set-tags>other</set-tags>
  <requester-name>#{@user.full_name}</requester-name>
  <requester-email>#{@user.email}</requester-email>
</ticket>
        EOF
      end
    end

  end

end
