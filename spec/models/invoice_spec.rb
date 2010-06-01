# == Schema Information
#
# Table name: invoices
#
#  id            :integer         not null, primary key
#  user_id       :integer
#  reference     :string(255)
#  state         :string(255)
#  charged_at    :datetime
#  started_at    :datetime
#  ended_at      :datetime
#  amount        :integer         default(0)
#  sites_amount  :integer         default(0)
#  videos_amount :integer         default(0)
#  sites         :text
#  videos        :text
#  created_at    :datetime
#  updated_at    :datetime
#

require 'spec_helper'

describe Invoice do
  
  context "with valid attributes" do
    subject { Factory(:invoice) }
    
    its(:reference) { should =~ /^[ABCDEFGHIJKLMNPQRSTUVWXYZ1-9]{8}$/ }
    it { should be_valid }
  end
  
  context "current" do
    before(:each) do
      @user  = Factory(:user, :last_invoiced_at => 1.day.ago, :next_invoiced_at => 1.day.from_now)
      @site1 = Factory(:site, :user => @user, :loader_hits_cache => 100, :js_hits_cache => 11)
      @site2 = Factory(:site, :user => @user, :loader_hits_cache => 50, :js_hits_cache => 5, :hostname => "google.com")
    end
    
    subject { Invoice.current(@user) }
    
    it { subject.reference.should be_nil } # not working with its...
    its(:started_at)    { should <= @user.last_invoiced_at }
    its(:ended_at)      { should <= Time.now.utc }
    its(:sites)         { should be_kind_of(Invoice::Sites) }
    its(:user)          { should be_present }
    its(:amount)        { should == 166 }
    its(:sites_amount)  { should == 166 }
    its(:videos_amount) { should == 0 }
    it { should be_current }
  end
  
end
