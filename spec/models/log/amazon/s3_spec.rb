# == Schema Information
#
# Table name: logs
#
#  id         :integer         not null, primary key
#  type       :string(255)
#  name       :string(255)
#  hostname   :string(255)
#  state      :string(255)
#  file       :string(255)
#  started_at :datetime
#  ended_at   :datetime
#  created_at :datetime
#  updated_at :datetime
#

require 'spec_helper'

describe Log::Amazon::S3 do
  
  context "built with valid attributes" do
    subject { Factory.build(:log_s3_videos, :name => '2010-06-23-08-20-45-DE5461BCB46DA093') }
    
    it { should be_unprocessed }
    it { should be_valid }
    its(:started_at) { should == Time.zone.parse('2010-06-23') }
    its(:ended_at)   { should == Time.zone.parse('2010-06-24') }
    
    it "should set hostname from logs.yml before_validation" do
      should be_valid
      subject.hostname == Log::Amazon::S3::Videos.config[:hostname]
    end
    it "should set file from name and bypass CarrierWave" do
      should be_valid
      subject.read_attribute(:file) == '2010-06-23-08-20-45-DE5461BCB46DA093'
    end
  end
  # 
  describe "Class Methods" do
    it "should download and save new logs & launch delayed job" do
      VCR.use_cassette('s3/logs_s3_videos_with_prefix') do
        lambda { Log::Amazon::S3::Videos.fetch_and_create_new_logs }.should change(Log::Amazon::S3::Videos, :count).by(35)
        Delayed::Job.first.name.should == 'Class#fetch_and_create_new_logs'
        Delayed::Job.last.name.should  == 'Log::Amazon::S3::Videos#process'
      end
    end
    
    it "should download and only save news logs" do
      VCR.use_cassette('s3/logs_s3_videos_with_prefix_and_marker') do
        Factory(:log_s3_videos, :name => '2010-06-23-08-20-45-DE5461BCB46DA093')
        Factory(:log_s3_videos, :name => '2010-06-23-15-26-27-DE1501337B998C43')
        lambda { Log::Amazon::S3::Videos.fetch_and_create_new_logs }.should change(Log::Amazon::S3::Videos, :count).by(25)
      end
    end
  end
  
end