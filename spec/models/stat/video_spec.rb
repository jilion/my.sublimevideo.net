require 'spec_helper'

describe Stat::Video do
  before(:each) { Pusher.stub(:[]) { mock('channel', trigger: nil) } }

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

    context "last 61 seconds" do
      before(:each) do
        @second = Time.utc(2011,11,21,12)
        Timecop.freeze @second do
          6.times do |video_i|
            Factory.create(:video_tag, st: 'site1234', u: "video#{video_i}", n: "Video #{video_i}", no: 'a')
            62.times do |second_i|
              next if second_i%2 == 0
              Factory.create(:video_stat, st: 'site1234', u: "video#{video_i}", s: (second_i).seconds.ago.utc.change(usec: 0),
                vv: { m: video_i + second_i, e: video_i + second_i },
                vl: { m: video_i * second_i, e: video_i * second_i }
              )
            end
          end
        end
      end

      specify { Timecop.freeze @second do
        Stat::Video.top_videos('site1234', period: 'seconds', count: 1)[:videos].size.should == 6
      end }
      specify { Timecop.freeze @second do
        Stat::Video.top_videos('site1234', period: 'seconds', count: 5)[:total].should == 6
      end }
      specify { Timecop.freeze @second do
        Stat::Video.top_videos('site1234', period: 'seconds', count: 5)[:from].should == 61.seconds.ago.utc.change(usec: 0).to_i
      end }

      it "replaces vv_hash by vv_array and vl_hash by vl_hash" do
        Timecop.freeze @second do
          videos = Stat::Video.top_videos('site1234', period: 'seconds', count: 5)[:videos].sort_by! { |video| video["n"] }.reverse
          video  = videos.first
          video["vv_sum"].should be_nil
          video["vv_array"].should be_nil
          video["vv_hash"].size.should eql(30)
          video["vv_hash"].should eql({"1321876797"=>16, "1321876795"=>20, "1321876793"=>24, "1321876791"=>28, "1321876789"=>32, "1321876787"=>36, "1321876785"=>40, "1321876783"=>44, "1321876781"=>48, "1321876779"=>52, "1321876777"=>56, "1321876775"=>60, "1321876773"=>64, "1321876771"=>68, "1321876769"=>72, "1321876767"=>76, "1321876765"=>80, "1321876763"=>84, "1321876761"=>88, "1321876759"=>92, "1321876757"=>96, "1321876755"=>100, "1321876753"=>104, "1321876751"=>108, "1321876749"=>112, "1321876747"=>116, "1321876745"=>120, "1321876743"=>124, "1321876741"=>128, "1321876739"=>132})
          video["vl_sum"].should be_nil
          video["vl_array"].should be_nil
          video["vl_hash"].size.should eql(30)
          video["vl_hash"].should eql({"1321876797"=>30, "1321876795"=>50, "1321876793"=>70, "1321876791"=>90, "1321876789"=>110, "1321876787"=>130, "1321876785"=>150, "1321876783"=>170, "1321876781"=>190, "1321876779"=>210, "1321876777"=>230, "1321876775"=>250, "1321876773"=>270, "1321876771"=>290, "1321876769"=>310, "1321876767"=>330, "1321876765"=>350, "1321876763"=>370, "1321876761"=>390, "1321876759"=>410, "1321876757"=>430, "1321876755"=>450, "1321876753"=>470, "1321876751"=>490, "1321876749"=>510, "1321876747"=>530, "1321876745"=>550, "1321876743"=>570, "1321876741"=>590, "1321876739"=>610})
        end
      end
    end

  end

end
