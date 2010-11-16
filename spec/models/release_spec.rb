require 'spec_helper'

describe Release do
  let(:archived_release) { Factory(:release).tap { |r| r.archive } }
  let(:dev_release) { Factory(:release) }
  let(:beta_release) { Factory(:release).tap { |r| r.flag } }
  let(:stable_release) { Factory(:release).tap { |r| 2.times { r.flag } } }
  
  before(:each) { VoxcastCDN.stub(:purge_dir) }
  
  context "with valid attributes" do
    before(:each) { VCR.insert_cassette('release/valid') }
    subject { dev_release }
    
    its(:date) { should =~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}$/ }
    its(:zip)  { should be_present }
    
    it { should be_dev }
    it { should be_valid }
    
    after(:each) { VCR.eject_cassette }
  end
  
  describe "validations" do
    it { should validate_presence_of(:zip) }
    
    it "should only allow zip file" do
      release = Factory.build(:release, :zip => File.new(Rails.root.join('spec/fixtures/railscast_intro.mov')))
      release.should_not be_valid
      release.errors[:zip].should include("is not an allowed file type")
    end
  end
  
  context "archived release" do
    before(:each) { VCR.insert_cassette('release/archived') }
    subject { archived_release }
    
    it { should be_archived }
    it "should not be archivable" do
      subject.archive.should be_false
    end
    it "should not save the zip locally when not flagging to dev (only during the flag after_transition, see #files_in_zip)" do
      File.file?(Rails.root.join("tmp/#{subject.zip.filename}")).should be_false
    end
    it "should purge /p/dev when flagged (becoming the dev release)" do
      VoxcastCDN.should_receive(:purge_dir).with('/p/dev')
      subject.flag
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
        keys_names = S3.keys_names(S3.player_bucket, 'prefix' => 'dev/', :remove_prefix => true)
        keys_names.sort.should == subject.files_in_zip.map(&:to_s).sort
      end
      
      it "should put zip files inside dev dir with public-read" do
        S3.player_bucket.keys('prefix' => 'dev').each do |key|
          all_users_grantee = key.grantees.detect { |g| g.name == "AllUsers" }
          all_users_grantee.perms.should == ["READ"]
        end
      end
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
  context "dev release" do
    before(:each) { VCR.insert_cassette('release/dev') }
    
    subject { dev_release }
    
    it { should be_dev }
    
    it "should be the dev release" do
      subject.should == Release.dev_release
    end
    
    it "should purge /p/beta when flagged (becoming the stable release)" do
      VoxcastCDN.should_receive(:purge_dir).with('/p/beta')
      subject.flag
    end
    
    describe "when flagged" do
      before(:each) do
        S3.player_bucket.put("beta/foo.txt", "bar")
        subject.flag
      end
      
      it { should be_beta }
      
      it "should remove no more used files in beta dir" do
        VCR.eject_cassette
        VCR.insert_cassette('release/dev_read')
        keys_names = S3.keys_names(S3.player_bucket, 'prefix' => 'beta')
        keys_names.should_not include("beta/foo.txt")
      end
      
      it "should copy dev files inside beta dir" do
        keys_names = S3.keys_names(S3.player_bucket, 'prefix' => 'beta/', :remove_prefix => true)
        keys_names.sort.should == subject.files_in_zip.map(&:to_s).sort
      end
      
      it "should copy dev files inside beta dir with public-read" do
        VCR.eject_cassette
        VCR.insert_cassette('release/dev_read')
        S3.player_bucket.keys('prefix' => 'beta').each do |key|
          all_users_grantee = key.grantees.detect { |g| g.name == "AllUsers" }
          all_users_grantee.perms.should == ["READ"]
        end
      end
    end
    
    describe "when archived" do
      before(:each) { subject.archive }
      
      it { should be_archived }
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
  context "beta release" do
    before(:each) { VCR.insert_cassette('release/beta') }
    
    subject { beta_release }
    
    it { should be_beta }
    
    it "should also be the dev release when no really dev release exists" do
      subject.should == Release.dev_release
    end
    
    it "should be the beta release" do
      subject.should == Release.beta_release
    end
    
    it "should purge /p when flagged (becoming the stable release)" do
      VoxcastCDN.should_receive(:purge_dir).with('/p')
      subject.flag
    end
    
    describe "when flagged" do
      before(:each) do
        @stable_release = stable_release
        subject.flag
      end
      
      it { should be_stable }
      it "should copy beta files inside stable dir" do
        keys_names = S3.keys_names(S3.player_bucket, 'prefix' => 'stable/', :remove_prefix => true)
        keys_names.sort.should == subject.files_in_zip.map(&:to_s).sort
      end
      it "should archive old stable_release" do
        @stable_release.reload.should be_archived
      end
    end
    describe "when archived" do
      before(:each) { subject.archive }
      
      it { should be_archived }
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
  context "stable release" do
    before(:each) { VCR.insert_cassette('release/stable') }
    
    subject { stable_release }
    
    it { should be_stable }
    
    it "should not be flaggable" do
      subject.flag.should be_false
    end
    it "should also be the dev release when no really dev release exists" do
      subject.should == Release.dev_release
    end
    it "should also be the beta releas when no really beta release existse" do
      subject.should == Release.beta_release
    end
    it "should be the stable release" do
      subject.should == Release.stable_release
    end
    
    describe "when archived" do
      before(:each) { subject.archive }
      
      it { should be_archived }
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
  describe "instance methods" do
    set(:dev_release) { VCR.use_cassette('release/dev') { Factory(:release) } }
    before(:all) { VCR.insert_cassette('release/valid') }
    subject { dev_release }
    # before(:each) { VCR.insert_cassette('release/valid') }
    
    subject { dev_release }
    
    describe "#zipfile" do
      it "should save the zip locally" do
        subject.zipfile
        File.file?(Rails.root.join("tmp/#{subject.zip.filename}")).should be_true
        subject.delete_zipfile
        File.file?(Rails.root.join("tmp/#{subject.zip.filename}")).should be_false
      end
      it "should return a Zip::Zipfile object" do
        subject.zipfile.should be_instance_of(Zip::ZipFile)
      end
    end
    
    describe "#files_in_zip" do
      it "should auto-clear the local zip file when called with a block" do
        subject.files_in_zip do |files_in_zip_array|
          File.file?(Rails.root.join("tmp/#{subject.zip.filename}")).should be_true
        end
        File.file?(Rails.root.join("tmp/#{subject.zip.filename}")).should be_false
      end
      it "should not clear the local zip file when called without block" do
        subject.files_in_zip
        File.file?(Rails.root.join("tmp/#{subject.zip.filename}")).should be_true
      end
    end
    
    describe "#delete_zipfile" do
      it "should clear the local zip file" do
        subject.zipfile
        File.file?(Rails.root.join("tmp/#{subject.zip.filename}")).should be_true
        subject.delete_zipfile
        File.file?(Rails.root.join("tmp/#{subject.zip.filename}")).should be_false
      end
    end
    
    after(:all) do
      VCR.eject_cassette
      subject.delete_zipfile if File.file?(Rails.root.join("tmp/#{subject.zip.filename}"))
    end
  end
  
end


# == Schema Information
#
# Table name: releases
#
#  id         :integer         not null, primary key
#  token      :string(255)
#  date       :string(255)
#  zip        :string(255)
#  state      :string(255)
#  created_at :datetime
#  updated_at :datetime
#

