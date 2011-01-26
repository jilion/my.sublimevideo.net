require 'spec_helper'

describe SitesHelper do

  describe "#sublimevideo_script_tag_for" do
    it "is should generate sublimevideo script_tag" do
      site =  Factory(:site)
      helper.sublimevideo_script_tag_for(site).should == "<script type=\"text/javascript\" src=\"http://cdn.sublimevideo.net/js/#{site.token}.js\"></script>"
    end
  end

end
