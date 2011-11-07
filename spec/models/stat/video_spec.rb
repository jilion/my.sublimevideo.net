require 'spec_helper'

describe Stat::Video do

  describe ".top_videos" do

    context "last 24 hours" do
      before(:each) do
        6.times do |video_i|
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

      specify {  Stat::Video.top_videos('site1234', period: 'hours', count: 5)[:videos].size.should == 5 }
      specify {  Stat::Video.top_videos('site1234', period: 'hours', count: 5)[:total].should == 6 }
      specify {  Stat::Video.top_videos('site1234', period: 'hours', count: 5)[:start_time].should == 24.hour.ago.utc.change(min: 0).to_i }

      it "adds video_tag meta data" do
        video = Stat::Video.top_videos('site1234', period: 'hours', count: 5)[:videos].first
        video["n"].should eql "Video 5"
        video["no"].should eql "a"
      end

      it "replaces vv_hash by vv_array" do
        video = Stat::Video.top_videos('site1234', period: 'hours', count: 5)[:videos].first
        video["vv_array"].should eql([56, 0, 52, 0, 48, 0, 44, 0, 40, 0, 36, 0, 32, 0, 28, 0, 24, 0, 20, 0, 16, 0, 12, 0])
        video["vv_array"].size.should eql(24)
        video["vv_hash"].should be_nil
      end
    end

  end

end
