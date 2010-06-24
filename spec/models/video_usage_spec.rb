# == Schema Information
#
# Table name: video_usages
#
#  id         :integer         not null, primary key
#  video_id   :integer
#  log_id     :integer
#  started_at :datetime
#  ended_at   :datetime
#  hits       :integer         default(0)
#  bandwidth  :integer         default(0)
#  created_at :datetime
#  updated_at :datetime
#

require 'spec_helper'

describe VideoUsage do
  
  context "build with valid attributes" do
    subject { Factory.build(:video_usage) }
    
    its(:hits)      { should == 0 }
    its(:bandwidth) { should == 0 }
    it { should be_valid }
  end
  
  context "saved with valid attributes" do
    # SOMETIMES PROBLEM HERE WHEN RUNNING ALL SPECS
    subject { Factory(:video_usage) }
    
    its(:started_at) { should == Time.zone.parse('2010-06-16') + 8.hours }
    its(:ended_at)   { should == Time.zone.parse('2010-06-16') + 9.hours }
  end
  
  describe "Trackers parsing with cloudfront download" do
    before(:each) do
      @video1 = Factory(:video)
      @video1.token = 'e14ab4de'
      @video1.save
      @video2 = Factory(:video, :user => @video1.user)
      @video2.token = '313asa32'
      @video2.save
      
      @log = Factory(:log_cloudfront_download)
      @trackers = LogAnalyzer.parse(@log.file, 'LogsFileFormat::CloudfrontDownload')
    end
    
    it "should clean trackers" do
      VideoUsage.hits_and_bandwidths_from(@trackers).should == {
        :hits => { "e14ab4de" => 1},
        :bandwidth => { "e14ab4de" => 134284, "g46g16dz" => 3509835, "313asa32" => 3696141 },
      }
    end
    
    it "should get tokens from trackers" do
      hits_and_bandwidths = VideoUsage.hits_and_bandwidths_from(@trackers)
      VideoUsage.tokens_from(hits_and_bandwidths).should == ["e14ab4de", "g46g16dz", "313asa32"]
    end
    
    it "should create only 2 video_usages from trackers" do
      Log::Cloudfront::Download.fetch_and_create_new_logs
      lambda { VideoUsage.create_usages_from_trackers!(@log, @trackers) }.should change(VideoUsage, :count).by(2)
    end
    
    it "should create usages from trackers" do
      VideoUsage.create_usages_from_trackers!(@log, @trackers)
      usages = VideoUsage.all
      usages.map(&:video).should include(@video1)
      usages.map(&:video).should include(@video2)
      usage = usages.select { |u| u.video == @video1 }.first
      usage.log.should       == @log
      usage.video.should     == @video1
      usage.hits.should      == 1
      usage.bandwidth.should == 134284
    end
  end
  
end