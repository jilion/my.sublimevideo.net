require 'spec_helper'

describe S3 do
  
  describe "yml key access" do
    subject { described_class }
    
    its(:cnamed)            { should be_false }
    its(:access_key_id)     { should be_present }
    its(:secret_access_key) { should be_present }
  end
  
  describe "yml key access on production" do
    before(:each) do
      Rails.stub(:env).and_return("production")
      S3.reset_yml_options
      ENV['S3_ACCESS_KEY_ID'] = 'aaa'
      ENV['S3_SECRET_ACCESS_KEY'] = 'bbb'
    end
    
    subject { described_class }
    
    its(:access_key_id)     { should == 'aaa' }
    its(:secret_access_key) { should == 'bbb' }
  end
  
  describe "logs list" do
    before(:all) { S3.reset_yml_options }
    
    it "should return max 100 keys" do
      VCR.use_cassette('s3/logs_bucket_all_keys') do
        S3.logs_name_list.should have(104).names
      end
    end
  end
  
end
