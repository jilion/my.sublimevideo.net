# == Schema Information
#
#  type            :integer   not null
#  subject         :string    not null
#  description     :text      not null
#  requester_name  :string
#  requester_email :string
#  
#

require 'spec_helper'

describe Ticket do
  let(:user)   { Factory(:user) }
  let(:ticket) { Ticket.new({ :user => Factory(:user), :type => "bug_report", :subject => "Subject", :description => "Description" }) }
  
  context "with valid attributes" do
    subject { ticket }
    
    its(:type)            { should == :bug_report }
    its(:subject)         { should == "Subject" }
    its(:description)     { should == "Description" }
    it { should be_valid }
  end
  
  describe "validates" do
    it "should validate presence of user" do
      ticket = Ticket.new({ :user => nil, :type => "bug_report", :subject => nil, :description => "Description" })
      ticket.should_not be_valid
      ticket.errors[:user].should be_present
    end
    it "should validate inclusion of type in possible types" do
      ticket = Ticket.new({ :user => user, :type => "foo", :subject => "Subject", :description => "Description" })
      ticket.should_not be_valid
      ticket.errors[:type].should be_present
    end
    it "should validate presence of subject" do
      ticket = Ticket.new({ :user => user, :type => "bug_report", :subject => nil, :description => "Description" })
      ticket.should_not be_valid
      ticket.errors[:subject].should be_present
    end
    it "should validate presence of description" do
      ticket = Ticket.new({ :user => user, :type => "bug_report", :subject => "Subject", :description => nil })
      ticket.should_not be_valid
      ticket.errors[:description].should be_present
    end
  end
  
  describe "class methods" do
    it ".ordered types should return ordered types and their associated tags" do
      if MySublimeVideo::Release.beta?
        Ticket.ordered_types.should == [
          { :bug_report => 'bug report' },
          { :improvement_suggestion => 'improvement suggestion' },
          { :feature_request => 'feature request' },
          { :other => 'other' }
        ]
      else
        Ticket.ordered_types.should == [
          { :bug_report => 'bug report' },
          { :improvement_suggestion => 'improvement suggestion' },
          { :feature_request => 'feature request' },
          { :other => 'other' }
        ]
      end
    end
    
    it ".unordered_types should return a hash of all types and their associated tags" do
      if MySublimeVideo::Release.beta?
        Ticket.unordered_types.should == {
          :bug_report => 'bug report',
          :improvement_suggestion => 'improvement suggestion',
          :feature_request => 'feature request',
          :other => 'other'
        }
      else
        Ticket.unordered_types.should == {
          :bug_report => 'bug report',
          :improvement_suggestion => 'improvement suggestion',
          :feature_request => 'feature request',
          :other => 'other'
        }
      end
    end
  end
  
  describe "instance methods" do
    
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
      
      it "should set the description for the ticket based on its description" do
        JSON.parse(Zendesk.get("/tickets/#{ticket.post_ticket}.json").body)["description"].should == ticket.description
      end
      
      it "should set the tags for the ticket based on its type" do
        JSON.parse(Zendesk.get("/tickets/#{ticket.post_ticket}.json").body)["current_tags"].should =~ %r(#{Ticket.unordered_types[ticket.type]})
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
      before(:each) { VCR.insert_cassette("ticket/verify_user") }
      
      it "should set the user as verified on zendesk" do
        VCR.use_cassette("ticket/post_ticket") { ticket.post_ticket }
        ticket.verify_user
        JSON.parse(Zendesk.get("/users/#{ticket.user.zendesk_id}.json").body)["is_verified"].should be_true
      end
      
      after(:each) { VCR.eject_cassette }
    end
  end
  
end