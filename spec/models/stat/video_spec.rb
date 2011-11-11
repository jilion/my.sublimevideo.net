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

      specify { Stat::Video.top_videos('site1234', period: 'hours', count: 5)[:videos].size.should == 5 }
      specify { Stat::Video.top_videos('site1234', period: 'hours', count: 5)[:total].should == 6 }
      specify { Stat::Video.top_videos('site1234', period: 'hours', count: 5)[:from].should == 24.hour.ago.utc.change(min: 0).to_i }

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

    context "last 61 seconds", :focus do
      before(:each) do
        @second = Time.now.change(usec: 0)
        Timecop.freeze @second do
          6.times do |video_i|
            Factory.create(:video_tag, st: 'site1234', u: "video#{video_i}", n: "Video #{video_i}", no: 'a')
            60.times do |second_i|
              next if second_i%2 == 0
              Factory.create(:video_stat, st: 'site1234', u: "video#{video_i}", s: (second_i).seconds.ago.utc.change(usec: 0),
                vv: { m: video_i + second_i, e: video_i + second_i },
                vl: { m: video_i * second_i, e: video_i * second_i }
              )
            end
          end
        end
      end

      specify { Stat::Video.top_videos('site1234', period: 'seconds', count: 1)[:videos].size.should == 6 }
      specify { Stat::Video.top_videos('site1234', period: 'seconds', count: 5)[:total].should == 6 }
      specify {
        Timecop.freeze @second do
          Stat::Video.top_videos('site1234', period: 'seconds', count: 5)[:from].should == 60.seconds.ago.utc.change(usec: 0).to_i
        end
      }

      it "replaces vv_hash by vv_array and vl_hash by vl_hash" do
        Timecop.freeze @second do
          video = Stat::Video.top_videos('site1234', period: 'seconds', count: 5)[:videos].first
          puts video
          video["vv_array"].should eql([0, 128, 0, 124, 0, 120, 0, 116, 0, 112, 0, 108, 0, 104, 0, 100, 0, 96, 0, 92, 0, 88, 0, 84, 0, 80, 0, 76, 0, 72, 0, 68, 0, 64, 0, 60, 0, 56, 0, 52, 0, 48, 0, 44, 0, 40, 0, 36, 0, 32, 0, 28, 0, 24, 0, 20, 0, 16, 0, 12])
          video["vv_array"].size.should eql(60)
          video["vv_hash"].should be_nil
          video["vl_array"].should eql([0, 590, 0, 570, 0, 550, 0, 530, 0, 510, 0, 490, 0, 470, 0, 450, 0, 430, 0, 410, 0, 390, 0, 370, 0, 350, 0, 330, 0, 310, 0, 290, 0, 270, 0, 250, 0, 230, 0, 210, 0, 190, 0, 170, 0, 150, 0, 130, 0, 110, 0, 90, 0, 70, 0, 50, 0, 30, 0, 10])
          video["vl_array"].size.should eql(60)
          video["vl_hash"].should be_nil
        end
      end
    end

  end

end
