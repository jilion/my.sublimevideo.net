require 'spec_helper'

describe VideoStatsMerger do

  context "with 1 week of existing stats" do
    let(:site_token) { 'site_token' }
    let(:uid) { 'uid' }
    let(:old_uid) { 'old_uid' }

    before {
      7.times do |index|
        create(:video_day_stat, st: site_token, u: old_uid, d: index.days.ago.utc.change(hour: 0),
          vl: { m: 1, e: 1 },
          vv: { i: 1, em: 2 },
          vlc: 2,
          vvc: 0,
          md: { h: { d: 2, m: 1 }, f: { d: 3 } },
          bp: { "saf-win" => 2, "saf-osx" => 4 }
        )
      end
      create(:video_day_stat, st: site_token, u: uid, d: 0.days.ago.utc.change(hour: 0),
        vl: { i: 1 },
        vv: { m: 2 },
        vlc: 0,
        vvc: 2,
        md: { h: { m: 3 }, f: { m: 1 } },
        bp: { "saf-win" => 1, "fir-win" => 2 }
      )
    }

    it "merges with new stats" do
      VideoStatsMerger.new(site_token, uid, old_uid).merge!
      stats = Stat::Video::Day.where(st: site_token, u: uid).order_by([:d, :desc])
      stats.should have(7).stats
      stats.first.md.should eq({ "f" => { "d" => 3, "m" => 1 }, "h" => { "d" => 2, "m" => 4 } })
    end

    it "removes old stats" do
      VideoStatsMerger.new(site_token, uid, old_uid).merge!
      Stat::Video::Day.where(st: site_token, u: old_uid).should have(0).stats
    end
  end

end
