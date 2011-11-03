require 'spec_helper'

describe Stat::Video do

  describe ".top_videos" do

    context "last 24 hours" do
      before(:each) do
        11.times do |video_i|
          Factory.create(:video_tag, st: 'site1234', u: "video#{video_i}", n: "Video #{video_i}")
          24.times do |hour_i|
            Factory.create(:video_stat, st: 'site1234', u: "video#{video_i}", h: (hour_i + 1).hours.ago.utc.change(m: 0), vv: { m: video_i * hour_i, e: video_i + hour_i })
          end
        end
      end

      it "does something" do
        # Stat::Video.top_videos('site1234', count: 10).size.should == 10
        p Stat::Video.top_videos('site1234', 'hours', count: 10)
      end
    end

  end

end
