require 'spec_helper'

describe Invoice do
  context "from factory" do
    set(:invoice_from_factory) { Factory(:invoice) }
    subject { invoice_from_factory }
    
    its(:user)       { should be_present }
    its(:reference)  { should =~ /^[A-Z1-9]{8}$/ }
    its(:amount)     { should be_nil }
    its(:started_on) { should == Time.now.utc.to_date }
    its(:ended_on)   { should be_nil }
    its(:charged_at) { should be_nil }
    its(:attempts)   { should == 0 }
    its(:last_error) { should be_nil }
    its(:failed_at)  { should be_nil }
    
    it { be_next }
    it { be_valid }
  end
  
  describe "associations" do
    set(:invoice_for_associations) { Factory(:invoice) }
    subject { invoice_for_associations }
    
    it { should belong_to :user }
    it { should have_many :invoice_items }
  end
  
  describe "validates" do
    subject { Factory(:invoice) }
    
    [:user_id, :started_on, :ended_on].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end
    
    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:started_on) }
    
    describe "uniqueness of open invoice" do
      it "should not allow two open invoices" do
        invoice2 = Factory.build(:invoice, :user => subject.user.reload)
        invoice2.should_not be_valid
        invoice2.errors[:state].should == ["'open' should be unique per user"]
      end
      
      it "should allow one next invoices (self)" do
        subject.charged_at = Time.now.utc
        subject.should be_valid
        subject.errors[:state].should be_empty
      end
    end
    
    context "with state unpaid" do
      before(:each) { subject.state = 'unpaid' }
      
      it { should validate_presence_of(:amount) }
      it { should validate_presence_of(:closed_on) }
    end
  end
  
  describe "callbacks" do
    
  end
  
  describe "State Machine" do
    subject { Factory(:invoice) }
    
    describe "initial state" do
      it { should be_open }
    end
    
    pending "prepare_for_charging" do
      before(:each) { subject.amount = 10 }
      
      it "should set state to ready" do
        subject.prepare_for_charging
        subject.should be_ready
      end
    end
    
    pending "archive" do
      before(:each) do
        subject.amount = 10
        subject.prepare_for_charging
      end
      
      it "should set state to archived" do
        subject.archive
        subject.should be_archived
      end
    end
  end
end


# == Schema Information
#
# Table name: invoices
#
#  id         :integer         not null, primary key
#  user_id    :integer
#  reference  :string(255)
#  state      :string(255)
#  amount     :integer
#  billed_on  :date
#  paid_at    :datetime
#  attempts   :integer         default(0)
#  last_error :string(255)
#  failed_at  :datetime
#  created_at :datetime
#  updated_at :datetime
#

