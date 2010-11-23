require 'spec_helper'

describe Invoice do
  set(:invoice) { Factory(:invoice) }
  
  context "from factory" do
    subject { invoice }
    
    its(:user)       { should be_present }
    its(:reference)  { should =~ /^[A-Z1-9]{8}$/ }
    its(:amount)     { should be_nil }
    its(:started_at) { should be_present }
    its(:ended_at)   { should be_present }
    its(:paid_at)    { should be_nil }
    its(:attempts)   { should == 0 }
    its(:last_error) { should be_nil }
    its(:failed_at)  { should be_nil }
    
    it { be_open }
    it { be_valid }
  end
  
  describe "associations" do
    subject { invoice }
    
    it { should belong_to :user }
    it { should have_many :invoice_items }
  end
  
  describe "validates" do
    subject { Factory(:invoice) }
    
    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:started_at) }
    it { should validate_presence_of(:ended_at) }
    
    context "with state unpaid" do
      before(:each) { subject.state = 'unpaid' }
      
      it { should validate_presence_of(:amount) }
    end
    
    context "with state paid" do
      before(:each) { subject.state = 'paid' }
    end
  end
  
  describe "callbacks" do
    
  end
  
  describe "State Machine" do
    subject { Factory(:invoice) }
    
    describe "initial state" do
      it { should be_open }
    end
    
    pending "unpaid state" do
      before(:each) { subject.amount = 10 }
      
      it "should set state to ready" do
        subject.ready
        subject.should unpaid
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
#  started_at :datetime
#  ended_at   :datetime
#  paid_at    :datetime
#  attempts   :integer         default(0)
#  last_error :string(255)
#  failed_at  :datetime
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_invoices_on_user_id                 (user_id)
#  index_invoices_on_user_id_and_ended_at    (user_id,ended_at) UNIQUE
#  index_invoices_on_user_id_and_started_at  (user_id,started_at) UNIQUE
#

