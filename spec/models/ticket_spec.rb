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
  let(:user) { Factory(:user) }
  
  describe "factory" do
    let(:ticket) { Ticket.new({ :user => user, :type => "bug-report", :subject => "Subject", :message => "Message" }) }
    subject { ticket }
    
    its(:type)    { should == "bug-report" }
    its(:subject) { should == "Subject" }
    its(:message) { should == "Message" }
    
    it { should be_valid }
  end
  
  describe "validates" do
    Ticket::TYPES.each do |type|
      it { should allow_value(type).for(:type) }
    end
    
    %w[foo bar test].each do |type|
      it { should_not allow_value(type).for(:type) }
    end
    
    it "should validate presence of user" do
      ticket = Ticket.new({ :user => nil, :type => "bug-report", :subject => nil, :message => "Message" })
      ticket.should_not be_valid
      ticket.errors[:user].should be_present
    end
    
    it "should validate presence of subject" do
      ticket = Ticket.new({ :user => user, :type => "bug-report", :subject => nil, :message => "Message" })
      ticket.should_not be_valid
      ticket.errors[:subject].should be_present
    end
    
    it "should validate presence of message" do
      ticket = Ticket.new({ :user => user, :type => "bug-report", :subject => "Subject", :message => nil })
      ticket.should_not be_valid
      ticket.errors[:message].should be_present
    end
  end
  
  describe "instance methods" do
    let(:ticket) { Ticket.new({ :user => user, :type => "bug-report", :subject => "Subject", :message => "Message" }) }
    
    describe "#save" do
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
      before(:each) { VCR.insert_cassette("ticket/post_ticket") }
      
      it "should create the ticket on Zendesk" do
        zendesk_tickets_count_before_post = VCR.use_cassette("ticket/zendesk_tickets_before_post") do
          JSON.parse(Zendesk.get("/rules/1447233.json").body).size
        end
        ticket.post_ticket
        VCR.use_cassette("ticket/zendesk_tickets_after_post") do
          JSON.parse(Zendesk.get("/rules/1447233.json").body).size.should  == zendesk_tickets_count_before_post + 1
        end
      end
      
      it "should set the subject for the ticket based on its subject" do
        JSON.parse(Zendesk.get("/tickets/#{ticket.post_ticket}.json").body)["subject"].should == ticket.subject
      end
      
      it "should set the message for the ticket based on its message" do
        JSON.parse(Zendesk.get("/tickets/#{ticket.post_ticket}.json").body)["description"].should == ticket.message
      end
      
      it "should set the tags for the ticket based on its type" do
        JSON.parse(Zendesk.get("/tickets/#{ticket.post_ticket}.json").body)["current_tags"].should =~ %r(#{ticket.type})
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
      
      after(:each) { VCR.eject_cassette }
    end
    
    describe "#verify_user" do
      it "should set the user as verified on zendesk" do
        VCR.use_cassette("ticket/post_ticket") { ticket.post_ticket }
        VCR.use_cassette("ticket/verify_user") do
          ticket.verify_user
          JSON.parse(Zendesk.get("/users/#{ticket.user.zendesk_id}.json").body)["is_verified"].should be_true
        end
      end
    end
  end
  
end