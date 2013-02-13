require 'fast_spec_helper'
require 'config/vcr'
require 'aws'

require 'wrappers/s3_wrapper'

describe S3Wrapper do

  describe '.bucket_url' do
    it { described_class.bucket_url('foo').should eq 'https://s3.amazonaws.com/foo/' }
  end

  describe ".keys_names" do
    use_vcr_cassette "s3/keys_names"

    it "should return the names of all keys" do
      S3Wrapper.keys_names(S3Wrapper.player_bucket).should == ["beta/black_pixel.gif",
           "beta/close_button.png",
           "beta/ie/transparent_pixel.gif",
           "beta/play_button.png",
           "beta/sublime.js",
           "beta/sublime.swf",
           "beta/sublime_css.js",
           "dev/black_pixel.gif",
           "dev/close_button.png",
           "dev/ie/transparent_pixel.gif",
           "dev/play_button.png",
           "dev/sublime.js",
           "dev/sublime.swf",
           "dev/sublime_css.js",
           "releases/2010-08-27-10-08-46-1B0RMZHB99.zip",
           "releases/2010-08-27-10-10-40-56K8NPQA4E.zip",
           "releases/2010-08-27-10-14-17-VHS9OSX6W3.zip",
           "releases/2010-10-11-14-31-49-H5S8PDSF9Z.zip",
           "releases/2010-10-11-14-37-49-0Z3J3WJORO.zip",
           "releases/2010-10-11-15-27-32-0FS5LH6LBF.zip",
           "releases/2010-10-11-15-29-14-UUH4VMI3DI.zip",
           "releases/2010-10-13-09-43-58-ND6N4IBYPB.zip",
           "releases/2010-10-13-09-46-39-DRXJLS4XM9.zip",
           "stable/",
           "stable/black_pixel.gif",
           "stable/close_button.png",
           "stable/ie/transparent_pixel.gif",
           "stable/play_button.png",
           "stable/sublime.js",
           "stable/sublime.swf",
           "stable/sublime_css.js"]
    end

    describe ":remove_prefix option" do
      it "should not remove prefix from key name when remove_prefix is not set" do
        S3Wrapper.keys_names(S3Wrapper.player_bucket, 'prefix' => 'dev').each do |key|
          key.should =~ /^dev/
        end
      end

      it "should not remove prefix from key name when remove_prefix is set to false" do
        S3Wrapper.keys_names(S3Wrapper.player_bucket, 'prefix' => 'dev', remove_prefix: false).each do |key|
          key.should =~ /^dev/
        end
      end

      it "should remove prefix from key name when remove_prefix is set to true" do
        S3Wrapper.keys_names(S3Wrapper.player_bucket, 'prefix' => 'dev', remove_prefix: true).each do |key|
          key.should_not =~ /^dev/
        end
      end
    end
  end

  describe ".buckets" do
    it "returns bucket name" do
      S3Wrapper.buckets['sublimevideo'].should eq 'dev.sublimevideo'
    end
  end

end
