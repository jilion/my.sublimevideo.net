# == Schema Information
#
# Table name: sites
#
#  id            :integer         not null, primary key
#  user_id       :integer
#  hostname      :string(255)
#  dev_hostnames :string(255)
#  token         :string(255)
#  state         :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#

require 'spec_helper'

describe Site do
  
  context "with valid attributes" do
    subject { Factory(:site) }
    
    it { subject.hostname.should      == "youtube.com"          }
    it { subject.dev_hostnames.should == "localhost, 127.0.0.1" }
    it { subject.user.should be_present                         }
    it { subject.should be_pending                              }
    it { subject.should be_valid                                }
  end
  
  describe "validates" do
    it "should validate presence of user" do
      site = Site.create(:user => nil)
      site.errors[:user].should be_present
    end
    it "should validate presence of hostname" do
      site = Site.create(:hostname => nil)
      site.errors[:hostname].should be_present
    end
    
    context "with already a site in db" do
      before(:each) { @site = Factory(:site) }
      
      it "should validate uniqueness of hostname by user" do
        site = @site.user.sites.create(:hostname => @site.hostname)
        site.errors[:hostname].should be_present
      end
    end
  end
  
end