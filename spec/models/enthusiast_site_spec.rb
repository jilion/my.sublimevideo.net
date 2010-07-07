# == Schema Information
#
# Table name: enthusiast_sites
#
#  id            :integer         not null, primary key
#  enthusiast_id :integer
#  hostname      :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#

require 'spec_helper'

describe EnthusiastSite do
  
  context "with valid attributes" do
    subject { Factory(:enthusiast_site) }
    
    its(:hostname)   { should == "youtube.com" }
    its(:enthusiast) { should be_present }
    it { be_valid }
  end
  
  describe "validations" do
    it "should validate presence of hostname" do
      enthusiast_site = Factory.build(:enthusiast_site, :hostname => nil)
      enthusiast_site.should_not be_valid
      enthusiast_site.should have(2).error_on(:hostname)
    end
    
    describe "validate hostname" do
      %w[http://asdasd slurp .com 901.12312.123 école école.fr üpper.de].each do |host|
        it "should validate validity of hostname: #{host}" do
          enthusiast_site = Factory.build(:enthusiast_site, :hostname => host)
          enthusiast_site.should_not be_valid
          enthusiast_site.should have(1).error_on(:hostname)
        end
      end
      
      %w[ftp://asdasad.com asdasd.com 124.123.151.123 htp://aasds.com www.youtube.com?video=31231].each do |host|
        it "should validate non-validity of hostname: #{host}" do
          enthusiast_site = Factory.build(:enthusiast_site, :hostname => host)
          enthusiast_site.should be_valid
          enthusiast_site.errors.should be_empty
        end
      end
    end
  end
  
end