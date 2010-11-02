require 'spec_helper'

describe Invoice do
  
  context "with valid attributes" do
    set(:invoice) { Factory(:invoice) }
    
    subject { invoice }
    
    its(:user)       { should be_present }
    its(:reference)  { should =~ /^[A-Z1-9]{8}$/ }
    its(:state)      { should == 'current' }
    its(:amount)     { should be_nil }
    its(:started_on) { should == Date.new(2010,1,1) }
    its(:ended_on)   { should == Date.new(2010,1,31) }
    its(:charged_at) { should be_nil }
    its(:attempts)   { should == 0 }
    its(:last_error) { should be_nil }
    its(:failed_at)  { should be_nil }
    
    it { be_valid }
  end
  
  describe "validates" do
    it { should belong_to :user }
    it { should have_many :invoice_items }
    
    # [:hostname, :dev_hostnames].each do |attr|
    #   it { should allow_mass_assignment_of(attr) }
    # end
    
    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:started_on) }
    it { should validate_presence_of(:ended_on) }
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
#  started_on :date
#  ended_on   :date
#  charged_at :datetime
#  attempts   :integer         default(0)
#  last_error :string(255)
#  failed_at  :datetime
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_invoices_on_user_id  (user_id)
#

