require 'fast_spec_helper'
require 'request_log_analyzer'

require 'log_file_formats/amazon_log_file_format'

describe AmazonLogFileFormat do
  subject { class Foo; include AmazonLogFileFormat; end; Foo.new }

  # ==========
  # = Player =
  # ==========

  ["GET /sublime.swf?t=6vibplhv HTTP/1.1", "HEAD /sublime.js?t=6vibplhv HTTP/1.0", "GET /sublime_css.js?t=6vibplhv FTP/1.1", "GET /close_button.png?t=6vibplhv HTTP/1.1", "GET /ie/transparent_pixel.gif?t=6vibplhv HTTP/1.1"].each do |requests_uri|
    it "should return player_token_from #{requests_uri}" do
      subject.player_token_from(requests_uri).should == "6vibplhv"
    end
    it "#{requests_uri} should be a player token" do
      subject.player_token?(requests_uri).should be_true
    end
  end

  ["GET /ie/transparent_pixel.gif HTTP/1.1", "GET /sublime.js?t=6vibp HTTP/1.1", "/sublime_css.js?t=6vibplhv"].each do |requests_uri|
    it "should not return player_token_from #{requests_uri}" do
      subject.player_token_from(requests_uri).should be_nil
    end
    it "#{requests_uri} should not be a player token" do
      subject.player_token?(requests_uri).should be_false
    end
  end

  # ===========
  # = Loaders =
  # ===========

  ['loaders/6vibplhv.js', '/loaders/6vibplhv.js'].each do |key|
    it "should return loader_token_from #{key}" do
      subject.loader_token_from(key).should == "6vibplhv"
    end
    it "#{key} should be a loader token" do
      subject.loader_token?(key).should be_true
    end
  end

  ['/js/6vibplhv.js', 'js/6vibplhv.js', "/ie/transparent_pixel.gif"].each do |key|
    it "should not return loader_token_from #{key}" do
      subject.loader_token_from(key).should be_nil
    end
    it "#{key} should not be a loader token" do
      subject.loader_token?(key).should be_false
    end
  end

  # ============
  # = Licenses =
  # ============

  ['licenses/6vibplhv.js', '/licenses/6vibplhv.js'].each do |key|
    it "should return license_token_from #{key}" do
      subject.license_token_from(key).should == "6vibplhv"
    end
    it "#{key} should be a license token" do
      subject.license_token?(key).should be_true
    end
  end

  ['/l/6vibplhv.js', 'l/6vibplhv.js', "/ie/transparent_pixel.gif"].each do |key|
    it "should not return license_token_from #{key}" do
      subject.license_token_from(key).should be_nil
    end
    it "#{key} should not be a license token" do
      subject.license_token?(key).should be_false
    end
  end

  # ================
  # = Other stuffs =
  # ================

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
