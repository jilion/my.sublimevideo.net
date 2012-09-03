require "fast_spec_helper"
require File.expand_path('app/helpers/video_tags_helper')

describe VideoTagsHelper do

  class Helper
    extend VideoTagsHelper
  end

  describe "duration_string" do
    it "renders one second when less than a seconds only properly" do
      Helper.duration_string(499).should eq "00:00"
    end
    it "renders seconds only properly" do
      Helper.duration_string(59*1000).should eq "00:59"
    end
    it "renders minutes only properly" do
      Helper.duration_string(60*1000).should eq "01:00"
    end
    it "renders hours only properly" do
      Helper.duration_string(60*60*1000).should eq "1:00:00"
    end
    it "renders a lot of hours only properly" do
      Helper.duration_string(25*60*60*1000).should eq "25:00:00"
    end
    it "renders complete duration properly" do
      Helper.duration_string(1*60*60*1000 + 34*60*1000 + 23*1000).should eq "1:34:23"
    end
  end
end
