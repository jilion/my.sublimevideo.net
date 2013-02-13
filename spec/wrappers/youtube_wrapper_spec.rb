require 'fast_spec_helper'
require 'active_support/core_ext'
require 'config/vcr'
require 'youtube_it'

require 'wrappers/youtube_wrapper'

describe YouTubeWrapper do

  before {
    Librato.stub(:increment)
  }

  context "with public video_id" do
    use_vcr_cassette "youtube/public_video_id"
    subject { described_class.new('DAcjV60RnRw') }

    its(:video_title) { should eq 'Will We Ever Run Out of New Music?' }
  end

  context "with private video_id" do
    use_vcr_cassette "youtube/private_video_id"
    subject { described_class.new('OmZyrynlk2w') }

    its(:video_title) { should be_nil }
  end

  context "with invalid video_id" do
    use_vcr_cassette "youtube/invalid_video_id"
    subject { described_class.new('invalid_video_id') }

    its(:video_title) { should be_nil }
  end

end
