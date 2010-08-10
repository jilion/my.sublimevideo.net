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
  
  context "with valid attributes" do
    subject { Ticket.new(Factory(:user), { :type => :signup, :subject => "Subject", :description => "Description" }) }
    
    its(:type)            { should == :signup }
    its(:subject)         { should == "Subject" }
    its(:description)     { should == "Description" }
    its(:requester_name)  { should be_present }
    its(:requester_email) { should be_present }
    it { should be_valid }
  end
  
  describe "validates" do
    it "should validate inclusion of type in possible types" do
      ticket = Ticket.new(Factory(:user), { :type => :foo, :subject => "Subject", :description => "Description" })
      ticket.should_not be_valid
      ticket.errors[:type].should be_present
    end
    it "should validate presence of subject" do
      ticket = Ticket.new(Factory(:user), { :type => :signup, :subject => nil, :description => "Description" })
      ticket.should_not be_valid
      ticket.errors[:subject].should be_present
    end
    it "should validate presence of description" do
      ticket = Ticket.new(Factory(:user), { :type => :signup, :subject => "Subject", :description => nil })
      ticket.should_not be_valid
      ticket.errors[:description].should be_present
    end
    it "should validate presence of requester_name" do
      ticket = Ticket.new(nil, { :type => :signup, :subject => "Subject", :description => "Description" })
      ticket.should_not be_valid
      ticket.errors[:requester_name].should be_present
    end
    it "should validate presence of requester_email" do
      ticket = Ticket.new(nil, { :type => :signup, :subject => "Subject", :description => "Description" })
      ticket.should_not be_valid
      ticket.errors[:requester_email].should be_present
    end
  end
  
  describe "class methods" do
    it ".ordered types should return ordered types and their associated tags" do
      Ticket.ordered_types.should == [
        { :signup => 'signup' },
        { :request => 'request' },
        { :billing => 'billing' },
        { :confused => 'confused' },
        { :broken => 'broken' },
        { :other => 'other' },
      ]
    end
    
    it ".unordered_types should return a hash of all types and their associated tags" do
      Ticket.unordered_types.should == {
        :signup => 'signup',
        :request => 'request',
        :billing => 'billing',
        :confused => 'confused',
        :broken => 'broken',
        :other => 'other'
      }
    end
  end
  
end