require 'spec_helper'

describe SitesHelper do

  describe "#sublimevideo_script_tag_for" do
    it "is should generate sublimevideo script_tag" do
      site =  FactoryGirl.create(:site)
      helper.sublimevideo_script_tag_for(site).should == "<script type=\"text/javascript\" src=\"http://cdn.sublimevideo.net/js/#{site.token}.js\"></script>"
    end
  end

  describe "#style_for_usage_bar_from_usage_percentage" do
    it { helper.style_for_usage_bar_from_usage_percentage(0).should == "display:none;" }
    it { helper.style_for_usage_bar_from_usage_percentage(0.0).should == "display:none;" }
    it { helper.style_for_usage_bar_from_usage_percentage(0.02).should == "width:4%;" }
    it { helper.style_for_usage_bar_from_usage_percentage(0.04).should == "width:4%;" }
    it { helper.style_for_usage_bar_from_usage_percentage(0.05).should == "width:5%;" }
    it { helper.style_for_usage_bar_from_usage_percentage(0.12344).should == "width:12.34%;" }
    it { helper.style_for_usage_bar_from_usage_percentage(0.783459).should == "width:78.35%;" }
  end

end
