require 'spec_helper'

describe StatsHelper do

  describe "auth_token" do
    let(:site) { double(token: 'site_token') }
    let(:video_tag) { double(uid: 'video_uid') }

    context "with only @site present" do
      before { assign(:site, site) }

      it "returns encrypted string with just site_token encrypted" do
        expect(helper.auth_token).to eq 'site_token:'.encrypt(:symmetric)
      end
    end

    context "with @site and @video_tag present" do
      before {
        assign(:site, site)
        assign(:video_tag, video_tag)
      }

      it "returns encrypted string with just site_token encrypted" do
        expect(helper.auth_token).to eq 'site_token:video_uid'.encrypt(:symmetric)
      end
    end
  end

end
