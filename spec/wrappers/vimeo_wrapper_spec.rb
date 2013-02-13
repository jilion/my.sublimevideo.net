require 'fast_spec_helper'
require 'vimeo'
require 'active_support/core_ext'
require 'config/vcr'

require 'wrappers/vimeo_wrapper'

describe VimeoWrapper do

  before {
    Librato.stub(:increment)
  }

  context "with public video_id" do
    use_vcr_cassette "vimeo/public_video_id"
    subject { described_class.new('35386044') }

    its(:video_title) { should eq 'Sony Professional - MCS-8M Switcher' }
  end

  context "with private video_id" do
    use_vcr_cassette "vimeo/private_video_id"
    subject { described_class.new('40711993') }

    its(:video_title) { should be_nil }
  end

  context "with invalid video_id" do
    use_vcr_cassette "vimeo/invalid_video_id"

    subject { described_class.new('invalid_video_id') }

    its(:video_title) { should be_nil }
  end

end
