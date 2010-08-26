# == Schema Information
#
# Table name: releases
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  zip        :string(255)
#  state      :string(255)
#  created_at :datetime
#  updated_at :datetime
#

require 'spec_helper'

describe Release do
  before(:each) { VCR.insert_cassette('release', :record => :all) }
  # before(:each) { VCR.insert_cassette('release') }
  
  context "with valid attributes" do
    subject { Factory(:release) }
    
    its(:name) { should =~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}$/ }
    its(:zip)  { should be_present }
    it { should be_dev }
    it { should be_valid }
    
    it { should validate_uniqueness_of :name }
  end
  
  it { should validate_presence_of(:zip) }
  it "should only allow zip file" do
    release = Factory.build(:release, :zip => File.new(Rails.root.join('spec/fixtures/railscast_intro.mov')))
    release.should have(2).error_on(:zip)
  end
  
  context "archived release" do
    subject do
      release = Factory(:release)
      release.archive
      release
    end
    
    it { should be_archived }
    
    it "should not be archivable" do
      subject.archive.should be_false
    end
    describe "when flagged"do
      before(:each) do
        S3.player_bucket.put("dev/foo.txt", "bar")
        subject.flag
      end
      
      it { should be_dev }
      it "should empty dev dir" do
        keys_name = S3.keys_names(S3.player_bucket, 'prefix' => 'dev')
        keys_name.should_not include("dev/foo.txt")
      end
      it "should put zip files inside dev dir" do
        keys_names = S3.player_bucket.keys('prefix' => 'dev').map(&:to_s)
        keys_names.map! { |name| name.gsub(/^dev\//, '') }
        keys_names.sort.should == subject.zip_files.map(&:to_s).sort
      end
      it "should put zip files inside dev dir with public-read" do
        S3.player_bucket.keys('prefix' => 'dev').each do |key|
          all_users_grantee = key.grantees.detect { |g| g.name == "AllUsers" }
          all_users_grantee.perms.should == ["READ"]
        end
      end
      
    end
  end
  
  context "dev release" do
    subject { Factory(:release) }
    
    it { should be_dev }
    
    describe "when flagged", :focus => true do
      before(:each) { subject.flag }
      
      it { should be_beta }
    end
    describe "when archived" do
      before(:each) { subject.archive }
      
      it { should be_archived }
    end
  end
  
  context "beta release" do
    subject do
      release = Factory(:release)
      release.flag
      release
    end
    
    it { should be_beta }
    
    describe "when flagged" do
      before(:each) { subject.flag }
      
      it { should be_stable }
    end
    describe "when archived" do
      before(:each) { subject.archive }
      
      it { should be_archived }
    end
  end
  
  context "stable release" do
    subject do
      release = Factory(:release)
      release.flag
      release.flag
      release
    end
    
    it { should be_stable }
    
    it "should not be flaggable" do
      subject.flag.should be_false
    end
    
    describe "when archived" do
      before(:each) { subject.archive }
      
      it { should be_archived }
    end
  end
  
  after(:each) { VCR.eject_cassette }
end