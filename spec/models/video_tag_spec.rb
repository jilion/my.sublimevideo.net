require 'fast_spec_helper'
require 'active_support/core_ext'
require 'support/private_api_helpers'

require 'video_tag'

describe VideoTag do
  let(:site_token) { 'site_token' }

  describe ".count" do
    before {
      stub_api_for(VideoTag) do |stub|
        stub.get("/private_api/sites/#{site_token}/video_tags/count") { |env| [200, {}, {count: 42}.to_json] }
      end
    }

    it "returns integer" do
      VideoTag.count(_site_token: site_token).should eq(42)
    end
  end

  describe "#backbone_data" do
    let(:video_tag) { VideoTag.new(title: 'Video Title', created_at: 1.day.ago) }

    it "slices only needed data" do
      video_tag.backbone_data.should eq(title: "Video Title")
    end
  end

  describe "#to_param" do
    let(:video_tag) { VideoTag.new(uid: 'uid') }

    it "uses uid" do
      video_tag.to_param.should eq video_tag.uid
    end
  end

  describe ".find" do
    it "raises ActiveRecord::RecordNotFound when uid is invalid" do
      expect { VideoTag.find(' a ', _site_token: 1) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

