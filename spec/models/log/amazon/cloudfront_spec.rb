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

describe Log::Amazon::Cloudfront do
  
  context "built with valid attributes" do
    subject { Factory.build(:log_cloudfront_download, :name => 'E3KTK13341WJO.2010-06-16-08.2Knk9kOC.gz') }
    
    it { should be_unprocessed }
    it { should be_valid }
    its(:started_at) { should == Time.zone.parse('2010-06-16') + 8.hours }
    its(:ended_at)   { should == Time.zone.parse('2010-06-16') + 9.hours }
    
    it "should set hostname from logs.yml before_validation" do
      should be_valid
      subject.hostname == Log::Amazon::Cloudfront::Download.config[:hostname]
    end
    it "should set file from name and bypass CarrierWave" do
      should be_valid
      subject.read_attribute(:file) == 'E3KTK13341WJO.2010-06-16-08.2Knk9kOC.gz'
    end
  end
  
  describe "Class Methods" do
    it "should download and save new logs & launch delayed job" do
      VCR.use_cassette('s3/logs_bucket_with_prefix') do
        lambda { Log::Amazon::Cloudfront::Download.fetch_and_create_new_logs }.should change(Log::Amazon::Cloudfront::Download, :count).by(6)
        Delayed::Job.last.name.should == 'Class#fetch_and_create_new_logs'
      end
    end
    
    it "should download and only save news logs" do
      VCR.use_cassette('s3/logs_bucket_with_prefix_and_marker') do
        Factory(:log_cloudfront_download, :name => 'E3KTK13341WJO.2010-06-17-11.O5iQjgcX.gz')
        Factory(:log_cloudfront_download, :name => 'E3KTK13341WJO.2009-06-17-11.O5iQjgcX.gz')
        lambda { Log::Amazon::Cloudfront::Download.fetch_and_create_new_logs }.should change(Log::Amazon::Cloudfront::Download, :count).by(3)
      end
    end
  end
  
end