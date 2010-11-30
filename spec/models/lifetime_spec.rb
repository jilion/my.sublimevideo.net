require 'spec_helper'

describe Lifetime do
  
  context "Factory" do
    before(:all) { @lifetime = Factory(:lifetime) }
    subject { @lifetime }
    
    its(:site)       { should be_present }
    its(:item)       { should be_present }
    its(:created_at) { should be_present }
    its(:deleted_at) { should be_nil }
    
    it { should be_valid }
  end # Factory
  
  describe "Associations" do
    before(:all) { @lifetime = Factory(:lifetime) }
    subject { @lifetime }
    
    it { should belong_to :site }
    it { should belong_to :item }
  end # Associations
  
  describe "Scopes" do
    describe "#alive_between scope" do
      before(:all) do
        @lifetime1 = Factory(:lifetime, :created_at => Time.utc(2010,1,15))
        @lifetime2 = Factory(:lifetime, :created_at => Time.utc(2010,2,15))
        @lifetime3 = Factory(:lifetime, :created_at => Time.utc(2010,2,1), :deleted_at => Time.utc(2010,2,2))
        @lifetime4 = Factory(:lifetime, :created_at => Time.utc(2010,2,1), :deleted_at => Time.utc(2010,2,20))
        @lifetime5 = Factory(:lifetime, :created_at => Time.utc(2010,2,1), :deleted_at => Time.utc(2010,2,28))
      end
      
      specify { Lifetime.alive_between(Time.utc(2010,1,1), Time.utc(2010,1,10)).should == [] }
      specify { Lifetime.alive_between(Time.utc(2010,1,1), Time.utc(2010,1,25)).should == [@lifetime1] }
      specify { Lifetime.alive_between(Time.utc(2010,2,5), Time.utc(2010,2,25)).should == [@lifetime1, @lifetime2, @lifetime4, @lifetime5] }
      specify { Lifetime.alive_between(Time.utc(2010,2,21), Time.utc(2010,2,25)).should == [@lifetime1, @lifetime2, @lifetime5] }
    end
  end # Scopes
  
end

# == Schema Information
#
# Table name: lifetimes
#
#  id         :integer         not null, primary key
#  site_id    :integer
#  item_type  :string(255)
#  item_id    :integer
#  created_at :datetime
#  deleted_at :datetime
#
# Indexes
#
#  index_lifetimes_created_at  (site_id,item_type,item_id,created_at)
#  index_lifetimes_deleted_at  (site_id,item_type,item_id,deleted_at) UNIQUE
#

