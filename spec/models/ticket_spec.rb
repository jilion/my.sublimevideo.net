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
  let(:user) { Factory(:user, first_name: "Rem & My") }

  describe "Factory" do
    let(:ticket) { Ticket.new({ :user => user, :type => "bug", :subject => "Subject", :message => "Message" }) }
    subject { ticket }

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

    it "should validate presence of user" do
      ticket = Ticket.new({ :user => nil, :type => "integration", :subject => nil, :message => "Message" })
      ticket.should_not be_valid
      ticket.errors[:user].should be_present
    end

    it "should validate presence of subject" do
      ticket = Ticket.new({ :user => user, :type => "idea", :subject => nil, :message => "Message" })
      ticket.should_not be_valid
      ticket.errors[:subject].should be_present
    end

    it "should validate presence of message" do
      ticket = Ticket.new({ :user => user, :type => "billing", :subject => "Subject", :message => nil })
      ticket.should_not be_valid
      ticket.errors[:message].should be_present
    end
  end

  describe "Instance Methods" do
    before(:all) do
      @user_with_launchpad_support = Factory(:user)
      Factory(:site, user: @user_with_launchpad_support, plan_id: @dev_plan.id)
      @user_with_standard_support = Factory(:user)
      Factory(:site, user: @user_with_standard_support, plan_id: @paid_plan.id)
      @user_with_priority_support = Factory(:user)
      Factory(:site, user: @user_with_priority_support, plan_id: @custom_plan.token)
    end

    describe "#save" do
      let(:ticket) { Ticket.new({ :user => @user_with_standard_support.reload, :type => "other", :subject => "I have a request!", :message => "I have a request this is a long text!" }) }

      it "should delay Ticket#post_ticket" do
        ticket.save
        Delayed::Job.last.name.should == 'Ticket#post_ticket'
      end
      it "should return true if all is good" do
        ticket.save.should be_true
      end
      it "should return false if not all is good" do
        ticket.user = nil
        ticket.save.should be_false
      end
    end

    describe "#post_ticket" do
      describe "common behavior" do
        let(:ticket) { Ticket.new({ :user => @user_with_standard_support.reload, :type => "idea", :subject => "I have a request!", :message => "I have a request this is a long text!" }) }
        use_vcr_cassette "ticket/post_ticket_standard_support"

        it "should create the ticket on Zendesk" do
          zendesk_tickets_count_before_post = VCR.use_cassette("ticket/zendesk_tickets_before_post") do
            JSON.parse(Zendesk.get("/rules/1447233.json").body).size
          end
          ticket.post_ticket
          VCR.use_cassette("ticket/zendesk_tickets_after_post") do
            JSON.parse(Zendesk.get("/rules/1447233.json").body).size.should == zendesk_tickets_count_before_post + 1
          end
        end

        it "should set the subject for the ticket based on its subject" do
          JSON.parse(Zendesk.get("/tickets/#{ticket.post_ticket}.json").body)["subject"].should == ticket.subject
        end

        it "should set the message for the ticket based on its message" do
          JSON.parse(Zendesk.get("/tickets/#{ticket.post_ticket}.json").body)["description"].should == ticket.message
        end

        it "should set the zendesk_id of the user if he didn't have one already" do
          ticket.user.zendesk_id.should be_nil
          ticket.post_ticket
          ticket.user.zendesk_id.should be_present
        end

        it "should delay Ticket#verify_user" do
          ticket.post_ticket
          Delayed::Job.last.name.should == 'Ticket#verify_user'
        end
      end

      context "user has standard support" do
        let(:ticket) { Ticket.new({ :user => @user_with_launchpad_support.reload, :type => "idea", :subject => "I have a request!", :message => "I have a request this is a long text!" }) }
        use_vcr_cassette "ticket/post_ticket_launchpad_support"

        it "should set the tags for the ticket based on its type" do
          JSON.parse(Zendesk.get("/tickets/#{ticket.post_ticket}.json").body)["current_tags"].should == "#{ticket.type} launchpad-support"
        end
      end

      context "user has standard support" do
        let(:ticket) { Ticket.new({ :user => @user_with_standard_support.reload, :type => "idea", :subject => "I have a request!", :message => "I have a request this is a long text!" }) }
        use_vcr_cassette "ticket/post_ticket_standard_support"

        it "should set the tags for the ticket based on its type" do
          JSON.parse(Zendesk.get("/tickets/#{ticket.post_ticket}.json").body)["current_tags"].should == "#{ticket.type} standard-support"
        end
      end

      context "user has priority support" do
        let(:ticket) { Ticket.new({ :user => @user_with_priority_support.reload, :type => "idea", :subject => "I have a request!", :message => "I have a request this is a long text!" }) }
        use_vcr_cassette "ticket/post_ticket_priority_support"

        it "should set the tags for the ticket based on its type" do
          JSON.parse(Zendesk.get("/tickets/#{ticket.post_ticket}.json").body)["current_tags"].should == "#{ticket.type} priority-support"
        end
      end
    end # #post_ticket

    describe "#verify_user" do
      let(:ticket) { Ticket.new({ :user => @user_with_standard_support.reload, :type => "idea", :subject => "I have a request!", :message => "I have a request this is a long text!" }) }

      it "should set the user as verified on zendesk" do
        VCR.use_cassette("ticket/post_ticket_standard_support") { ticket.post_ticket }
        VCR.use_cassette("ticket/verify_user") do
          ticket.verify_user
          JSON.parse(Zendesk.get("/users/#{ticket.user.zendesk_id}.json").body)["is_verified"].should be_true
        end
      end
    end # #verify_user

  end

end
