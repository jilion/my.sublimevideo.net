require 'spec_helper'

describe LogsFileFormat::Amazon do
  subject { class Foo; include LogsFileFormat::Amazon; end; Foo.new }
  
  it "should return token_from cloudfront download path" do
    subject.token_from("/g46g16dz/dartmoor.mp4").should == "g46g16dz"
  end
  
  it "should return token_from cloudfront streaming path" do
    subject.token_from("g46g16dz/dartmoor.mp4").should == "g46g16dz"
  end
  
  ['REST.GET.OBJECT', 'REST.GET.BUCKET', 'REST.HEAD.OBJECT'].each do |operation|
    it "#{operation} should be a S3 GET request" do
      subject.s3_get_request?(operation).should be_true
    end
  end
  
  ['REST.POST.OBJECT', 'REST.PUT.OBJECT', 'REST.DELETE.OBJECT'].each do |operation|
    it "#{operation} should not be a S3 GET request" do
      subject.s3_get_request?(operation).should be_false
    end
  end
  
  ['/k3zph1mc/best_snowboard_video_ever_720p.mp4', 'k3zph1mc/best_snowboard_video_ever_720p.webm'].each do |path|
    it "#{path} should be a video path" do
      subject.video_path?(path).should be_true
    end
  end
  
  ['/k3zph1mc/posterframe.jpg', 'posterframe.png'].each do |path|
    it "#{path} should not be a video path" do
      subject.video_path?(path).should be_false
    end
  end
  
  %w[SFO4 MIA3 JFK1 SEA4 DFW3 LAX1 IAD2 STL2 EWR2].each do |location|
    it "#{location} should be US location" do
      subject.us_location?(location).should be_true
    end
  end
  
  %w[FRA2 LHR3 AMS1 DUB1].each do |location|
    it "#{location} should be EU location" do
      subject.eu_location?(location).should be_true
    end
  end
  
  %w[HKG1 SIN2].each do |location|
    it "#{location} should be Asian location" do
      subject.as_location?(location).should be_true
    end
  end
  
  %w[NRT4].each do |location|
    it "#{location} should be Japan location" do
      subject.jp_location?(location).should be_true
    end
  end
  
  %w[CHF1 SUB3 XBL5].each do |location|
    it "#{location} should be unknown location" do
      subject.unknown_location?(location).should be_true
    end
  end
  
end