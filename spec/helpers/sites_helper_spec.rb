require 'spec_helper'

describe SitesHelper, :plans do

  describe "#sublimevideo_script_tag_for" do
    it "is should generate sublimevideo script_tag" do
      site = build(:fake_site)
      helper.sublimevideo_script_tag_for(site).should eq "<script type=\"text/javascript\" src=\"http://cdn.sublimevideo.net/js/#{site.token}.js\"></script>"
    end
  end

  describe "#style_for_usage_bar_from_usage_percentage" do
    it { helper.style_for_usage_bar_from_usage_percentage(0).should eq "display:none;" }
    it { helper.style_for_usage_bar_from_usage_percentage(0.0).should eq "display:none;" }
    it { helper.style_for_usage_bar_from_usage_percentage(0.02).should eq "width:4%;" }
    it { helper.style_for_usage_bar_from_usage_percentage(0.04).should eq "width:4%;" }
    it { helper.style_for_usage_bar_from_usage_percentage(0.05).should eq "width:5%;" }
    it { helper.style_for_usage_bar_from_usage_percentage(0.12344).should eq "width:12.34%;" }
    it { helper.style_for_usage_bar_from_usage_percentage(0.783459).should eq "width:78.35%;" }
  end

  describe "#hostname_or_token" do
    context "site with a hostname" do
      let(:site) { build(:fake_site, hostname: 'rymai.me') }

      specify { helper.hostname_or_token(site).should eq 'rymai.me' }
    end

    context "site without a hostname" do
      let(:site) { build(:fake_site, plan_id: @free_plan.id, hostname: '') }

      specify { helper.hostname_or_token(site).should eq "##{site.token}" }
    end
  end

end
