# == Schema Information
#
# Table name: video_usages
#
#  id               :integer         not null, primary key
#  video_id         :integer
#  log_id           :integer
#  started_at       :datetime
#  ended_at         :datetime
#  hits             :integer(8)      default(0)
#  traffic_s3       :integer(8)      default(0)
#  traffic_us       :integer(8)      default(0)
#  traffic_eu       :integer(8)      default(0)
#  traffic_as       :integer(8)      default(0)
#  traffic_jp       :integer(8)      default(0)
#  traffic_unknown  :integer(8)      default(0)
#  requests_s3      :integer(8)      default(0)
#  requests_us      :integer(8)      default(0)
#  requests_eu      :integer(8)      default(0)
#  requests_as      :integer(8)      default(0)
#  requests_jp      :integer(8)      default(0)
#  requests_unknown :integer(8)      default(0)
#  created_at       :datetime
#  updated_at       :datetime
#

require 'spec_helper'

describe VideoUsage do
  
  context "build with valid attributes" do
    subject { Factory.build(:video_usage) }
    
    its(:hits)             { should == 0 }
    its(:traffic_s3)       { should == 0 }
    its(:traffic_us)       { should == 0 }
    its(:traffic_eu)       { should == 0 }
    its(:traffic_as)       { should == 0 }
    its(:traffic_jp)       { should == 0 }
    its(:traffic_unknown)  { should == 0 }
    its(:requests_s3)      { should == 0 }
    its(:requests_us)      { should == 0 }
    its(:requests_eu)      { should == 0 }
    its(:requests_as)      { should == 0 }
    its(:requests_jp)      { should == 0 }
    its(:requests_unknown) { should == 0 }
    it { should be_valid }
  end
  
  context "saved with valid attributes" do
    subject { Factory(:video_usage) }
    
    its(:started_at) { should == Time.zone.parse('2010-06-16') + 8.hours }
    its(:ended_at)   { should == Time.zone.parse('2010-06-16') + 9.hours }
  end
  
  it "should notify if requests_unknown is greather than " do
    usage = Factory.build(:video_usage, :requests_unknown => 1)
    HoptoadNotifier.should_receive(:notify)
    usage.save
  end
  it "should notify if traffic_unknown is greather than " do
    usage = Factory.build(:video_usage, :traffic_unknown => 1)
    HoptoadNotifier.should_receive(:notify)
    usage.save
  end
  
  describe "Trackers parsing with cloudfront download" do
    before(:each) do
      VCR.insert_cassette('cloudfront/download/logs_list')
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
      VideoUsage.hits_traffic_and_requests_from(@trackers).should == {
        :hits => { "e14ab4de" => 1, "g46g16dz" => 1, "313asa32" => 1 },
        :traffic_us => {},
        :traffic_eu => { "e14ab4de" => 134284, "g46g16dz" => 3509835, "313asa32" => 3696141 },
        :traffic_as => {},
        :traffic_jp => {},
        :traffic_unknown => {},
        :requests_us => {},
        :requests_eu => { "g46g16dz" => 5, "e14ab4de" => 4, "313asa32" => 2 },
        :requests_as => {},
        :requests_jp => {},
        :requests_unknown => {}
      }
    end
    
    it "should get tokens from trackers" do
      hbr = VideoUsage.hits_traffic_and_requests_from(@trackers)
      VideoUsage.tokens_from(hbr).sort.should == ["g46g16dz", "e14ab4de", "313asa32"].sort
    end
    
    it "should create only 2 video_usages from trackers" do
      Log::Amazon::Cloudfront::Download.fetch_and_create_new_logs
      lambda { VideoUsage.create_usages_from_trackers!(@log, @trackers) }.should change(VideoUsage, :count).by(2)
    end
    
    it "should create usages from trackers" do
      VideoUsage.create_usages_from_trackers!(@log, @trackers)
      usages = VideoUsage.all
      usages.map(&:video).should include(@video1)
      usages.map(&:video).should include(@video2)
      usage = usages.select { |u| u.video == @video1 }.first
      usage.log.should          == @log
      usage.video.should        == @video1
      usage.hits.should         == 1
      usage.traffic_eu.should == 134284
      usage.requests_eu.should  == 4
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
  describe "Trackers parsing with s3 videos" do
    before(:each) do
      VCR.insert_cassette('s3/videos/logs_list')
      @video = Factory(:video)
      @video.token = '4e1az9e5'
      @video.save
      
      @log = Factory(:log_s3_videos)
      @trackers = LogAnalyzer.parse(@log.file, 'LogsFileFormat::S3Videos')
    end
    
    it "should clean trackers" do
      VideoUsage.hits_traffic_and_requests_from(@trackers).should == {
        :traffic_s3 => { "4e1az9e5" => 15392947717 },
        :requests_s3 => { "4e1az9e5" => 25 }
      }
    end
    
    it "should get tokens from trackers" do
      hbr = VideoUsage.hits_traffic_and_requests_from(@trackers)
      VideoUsage.tokens_from(hbr).should == ["4e1az9e5"]
    end
    
    it "should create only 1 video_usages from trackers" do
      Log::Amazon::S3::Videos.fetch_and_create_new_logs
      lambda { VideoUsage.create_usages_from_trackers!(@log, @trackers) }.should change(VideoUsage, :count).by(1)
    end
    
    it "should create usages from trackers" do
      VideoUsage.create_usages_from_trackers!(@log, @trackers)
      usage = VideoUsage.first
      usage.log.should          == @log
      usage.video.should        == @video
      usage.hits.should         == 0
      usage.traffic_s3.should == 15392947717
      usage.requests_s3.should  == 25
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
end
