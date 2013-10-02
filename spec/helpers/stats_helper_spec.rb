require 'spec_helper'

describe StatsHelper do

  describe "pusher_channel" do
    let(:site) { double(token: 'site_token') }
    let(:video_tag) { double(uid: 'video_uid') }

    context "with only @site present" do
      before { assign(:site, site) }

      specify { expect(helper.pusher_channel).to eq 'private-site_token' }
    end

    context "with @site and @video_tag present" do
      before {
        assign(:site, site)
        assign(:video_tag, video_tag)
      }

      specify { expect(helper.pusher_channel).to eq 'private-site_token.video_uid' }
    end
  end

end
