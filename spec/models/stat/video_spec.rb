require 'spec_helper'

describe Stat::Video do

  describe ".top_videos" do

    context "last 24 hours" do
      before(:each) do
        11.times do |video_i|
          Factory.create(:video_tag, st: 'site1234', u: "video#{video_i}", n: "Video #{video_i}", no: 'a')
          24.times do |hour_i|
            next if hour_i%2 == 0
            Factory.create(:video_stat, st: 'site1234', u: "video#{video_i}", h: (hour_i + 1).hours.ago.utc.change(min: 0),
              vv: { m: video_i + hour_i, e: video_i + hour_i },
              vl: { m: video_i * hour_i, e: video_i * hour_i }
            )
          end
        end
      end

      specify {  Stat::Video.top_videos('site1234', 'hours', count: 9)[:videos].size.should == 9 }
      specify {  Stat::Video.top_videos('site1234', 'hours', count: 9)[:total].should == 11 }
      specify {  Stat::Video.top_videos('site1234', 'hours', count: 9)[:start_time].should == 24.hour.ago.utc.change(min: 0) }

      it "adds video_tag meta data" do
        video = Stat::Video.top_videos('site1234', 'hours', count: 10)[:videos].first
        video["n"].should eql "Video 10"
        video["no"].should eql "a"
      end

      it "replaces vv_hash by vv_array" do
        video = Stat::Video.top_videos('site1234', 'hours', count: 10)[:videos].first
        video["vv_array"].should eql([66, 0, 62, 0, 58, 0, 54, 0, 50, 0, 46, 0, 42, 0, 38, 0, 34, 0, 30, 0, 26, 0, 22, 0])
        video["vv_hash"].should be_nil
      end
    end

  end

end
