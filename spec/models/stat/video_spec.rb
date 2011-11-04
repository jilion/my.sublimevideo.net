require 'spec_helper'

describe Stat::Video do

  describe ".top_videos" do

    context "last 24 hours" do
      before(:each) do
        11.times do |video_i|
          Factory.create(:video_tag, st: 'site1234', u: "video#{video_i}", n: "Video #{video_i}", no: 'a')
          12.times do |hour_i|
            next if hour_i%2 == 0
            Factory.create(:video_stat, st: 'site1234', u: "video#{video_i}", h: (hour_i + 1).hours.ago.utc.change(m: 0),
              vv: { m: video_i + hour_i, e: video_i + hour_i },
              vl: { m: video_i * hour_i, e: video_i * hour_i }
            )
          end
        end
      end

      specify {  Stat::Video.top_videos('site1234', 'hours', count: 9).size.should == 9 }

      it "add video_tag meta data" do
        video = Stat::Video.top_videos('site1234', 'hours', count: 10).first
        video["n"].should eql "Video 10"
        video["no"].should eql "a"
      end

      pending "add vv array" do
        video = Stat::Video.top_videos('site1234', 'hours', count: 10).first
        video["vv_array"].should eql([])
      end
    end

  end

end
