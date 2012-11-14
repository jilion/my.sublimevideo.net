require 'spec_helper'

describe Stat::Site do

  describe ".json" do
    let(:site) { create(:site) }
    after { Timecop.return }

    before do
      @second = Time.now.utc.change(usec: 0)
      create(:site_second_stat, t: site.token, d: (@second - 62.seconds), vv: { e: 1 })
      create(:site_second_stat, t: site.token, d: (@second - 61.seconds), vv: { e: 2 })
      create(:site_second_stat, t: site.token, d: (@second - 60.seconds), vv: { e: 3 })
      create(:site_second_stat, t: site.token, d: (@second - 2.second), vv: { e: 4 })
      create(:site_second_stat, t: site.token, d: (@second - 1.second), vv: { e: 5 })
      create(:site_second_stat, t: site.token, d: @second, vv: { e: 5 })

      create(:site_minute_stat, t: site.token, d: 60.minutes.ago.change(sec: 0), vv: { e: 2 })
      create(:site_minute_stat, t: site.token, d: 59.minutes.ago.change(sec: 0), vv: { e: 3 })
      create(:site_minute_stat, t: site.token, d: 1.minute.ago.change(sec: 0), vv: { e: 4 })
      create(:site_minute_stat, t: site.token, d: Time.now.utc.change(sec: 0), vv: { e: 5 })

      create(:site_hour_stat, t: site.token, d: 24.hours.ago.change(min: 0, sec: 0), vv: { e: 47 })
      create(:site_hour_stat, t: site.token, d: 23.hours.ago.change(min: 0, sec: 0), vv: { e: 48 })
      create(:site_hour_stat, t: site.token, d: 1.hours.ago.change(min: 0, sec: 0), vv: { e: 49 })
      create(:site_hour_stat, t: site.token, d: Time.now.utc.change(min: 0, sec: 0), vv: { e: 50 })

      @day400 = create(:site_day_stat, t: site.token, d: 400.days.ago.midnight, vv: { e: 100 })
      create(:site_day_stat, t: site.token, d: 3.days.ago.midnight, vv: { e: 101 })
      create(:site_day_stat, t: site.token, d: 1.day.ago.midnight, vv: { e: 102 })
      create(:site_day_stat, t: site.token, d: Time.now.utc.midnight, vv: { e: 103 })

      @mock_site = mock_model(Site)
      Site.stub(:find_by_token).and_return(@mock_site)
    end

    describe "with seconds period (missing value not filled)" do
      before { Timecop.travel(@second) }
      subject { JSON.parse(Stat::Site.json(site.token, period: 'seconds')) }

      its(:size) { should eql(3) }
      it { subject[0]['vv'].should eql(2) }
      it { subject[1]['vv'].should eql(3) }
      it { subject[2]['vv'].should eql(4) }

      it { subject[0]['id'].should eql((@second - 61.seconds).to_i) }
      it { subject[2]['id'].should eql((@second - 2.second).to_i) }
    end

    describe "with minutes period" do
      before { Timecop.freeze }
      subject { JSON.parse(Stat::Site.json(site.token, period: 'minutes')) }

      its(:size) { should eql(60) }
      it { subject[0]['vv'].should eql(3) }
      it { subject[1]['vv'].should eql(nil) }
      it { subject[58]['vv'].should eql(4) }
      it { subject[59]['vv'].should eql(5) }

      it { subject[0]['id'].should eql(59.minutes.ago.change(sec: 0).to_i) }
      it { subject[1]['id'].should eql(58.minutes.ago.change(sec: 0).to_i) }
      it { subject[59]['id'].should eql(Time.now.utc.change(sec: 0).to_i) }
    end

    describe "with hours period" do
      before { Timecop.freeze }
      subject { JSON.parse(Stat::Site.json(site.token, period: 'hours')) }

      its(:size) { should eql(24) }
      it { subject[0]['vv'].should eql(47) }
      it { subject[1]['vv'].should eql(48) }
      it { subject[2]['vv'].should eql(nil) }
      it { subject[23]['vv'].should eql(49) }

      it { subject[0]['id'].should eql(24.hours.ago.change(min: 0, sec: 0).to_i) }
      it { subject[2]['id'].should eql(22.hours.ago.change(min: 0, sec: 0).to_i) }
      it { subject[23]['id'].should eql(1.hours.ago.change(min: 0, sec: 0).to_i) }
    end

    describe "with days period" do
      before { Timecop.freeze }
      subject { JSON.parse(Stat::Site.json(site.token, period: 'days')) }

      its(:size) { should eql(400) }
      it { subject[0]['vv'].should eql(100) }
      it { subject[1]['vv'].should eql(nil) }
      it { subject[397]['vv'].should eql(101) }
      it { subject[399]['vv'].should eql(102) }
      it { subject[0]['id'].should eql(400.days.ago.change(hour: 0, min: 0, sec: 0).to_i) }
      it { subject[1]['id'].should eql(399.days.ago.change(hour: 0, min: 0, sec: 0).to_i) }
      it { subject[399]['id'].should eql(1.days.ago.change(hour: 0, min: 0, sec: 0).to_i) }
    end

    describe "with days period (less than 365 days stats)" do
      before { @day400.delete }
      before { Timecop.freeze }
      subject { JSON.parse(Stat::Site.json(site.token, period: 'days')) }

      its(:size) { should eql(365) }
      it { subject[0]['vv'].should eql(nil) }
      it { subject[1]['vv'].should eql(nil) }
      it { subject[364]['vv'].should eql(102) }
      it { subject[0]['id'].should eql(365.day.ago.change(hour: 0, min: 0, sec: 0).to_i) }
      it { subject[364]['id'].should eql(1.day.ago.change(hour: 0, min: 0, sec: 0).to_i) }
    end
  end
end

describe Stat::Site::Day do
  before { Timecop.freeze }
  after { Timecop.return }

  describe ".views_sum" do
    let(:site1) { create(:site) }
    let(:site2) { create(:site) }
    before do
      create(:site_day_stat, t: site1.token, d: 30.days.ago.midnight, pv: { e: 1 }, vv: { m: 2 })
      create(:site_day_stat, t: site1.token, d: Time.now.utc.midnight, pv: { e: 3 }, vv: { m: 4 })
      create(:site_day_stat, t: site2.token, d: 30.days.ago.midnight, pv: { e: 5 }, vv: { m: 6 })
      create(:site_day_stat, t: site2.token, d: Time.now.utc.midnight, pv: { e: 7 }, vv: { m: 8 })
    end

    describe "options" do
      describe ":token" do
        describe "with a single token" do
          subject { described_class.views_sum(token: site1.token) }

          it { should eql 6 }
        end

        describe "with an array of tokens" do
          subject { described_class.views_sum(token: [site1.token, site2.token]) }

          it { should eql 20 }
        end

        describe "with an unexisting token" do
          subject { described_class.views_sum(token: 'other-token') }

          it { should eql 0 }
        end
      end

      describe ":view_type" do
        describe "defaults to 'vv" do
          subject { described_class.views_sum(token: site1.token) }

          it { should eql 6 }
        end

        describe "accepts 'pv'" do
          subject { described_class.views_sum(token: site1.token, view_type: 'pv') }

          it { should eql 4 } # 1 + 3
        end
      end

      describe ":from & :to" do
        subject { described_class.views_sum(token: site1.token, from: 2.days.ago.utc, to: Time.now.utc) }

        it { should eql 4 }
      end
    end
  end

  describe ".last_stats" do

    let(:site1) { create(:site) }
    let(:site2) { create(:site) }
    before { Timecop.freeze }
    before do
      create(:site_day_stat, t: site1.token, d: 30.days.ago.midnight, pv: { e: 1 }, vv: { m: 2 })
      create(:site_day_stat, t: site1.token, d: Time.now.utc.midnight, pv: { e: 3 }, vv: { m: 4 })
      create(:site_day_stat, t: site2.token, d: 30.days.ago.midnight, pv: { e: 5 }, vv: { m: 6 })
      create(:site_day_stat, t: site2.token, d: Time.now.utc.midnight, pv: { e: 7 }, vv: { m: 8 })
    end
    after { Timecop.return }

    describe "options" do

      describe ":token" do
        describe "with a single token" do
          subject { described_class.last_stats(token: site1.token, fill_missing_days: false) }

          its(:size) { should eql(2) }
          it { subject.first['d'].to_time.should eql 30.days.ago.midnight.to_time }
          it { subject.first['vv']['m'].should eql(2) }
          it { subject.second['d'].to_time.should eql Time.now.utc.midnight.to_time }
          it { subject.second['vv']['m'].should eql(4) }
        end

        describe "with no token and no stats" do
          context "fill_missing_days is false" do
            subject { described_class.last_stats(fill_missing_days: false) }

            its(:size) { should eql(2) }
            it { subject.first['d'].to_time.should eql 30.days.ago.midnight.to_time }
            it { subject.first['vv']['m'].should eq 8 }
            it { subject.second['d'].to_time.should eql Time.now.utc.midnight.to_time }
            it { subject.second['vv']['m'].should eq 12 }
          end

          context "fill_missing_days is true" do
            subject { described_class.last_stats(fill_missing_days: true) }

            its(:size) { should eql(31) }
            it { subject.first['d'].to_time.should eql 30.days.ago.midnight.to_time }
            it { subject.first['vv']['m'].should eq 8 }
            it { subject.last['d'].to_time.should eql Time.now.utc.midnight.to_time }
            it { subject.last['vv']['m'].should eq 12 }
          end
        end

        describe "with an array of tokens" do
          context "fill_missing_days is false" do
            subject { described_class.last_stats(token: [site1.token, site2.token], fill_missing_days: false) }

            its(:size) { should eql(2) }
            it { subject.first['d'].to_time.should eql 30.days.ago.midnight.to_time }
            it { subject.first['vv']['m'].should eq 8 }
            it { subject.second['d'].to_time.should eql Time.now.utc.midnight.to_time }
            it { subject.second['vv']['m'].should eq 12 }
          end

          context "fill_missing_days is true" do
            subject { described_class.last_stats(token: [site1.token, site2.token], fill_missing_days: true) }

            its(:size) { should eql(31) }
            it { subject.first['d'].to_time.should eql 30.days.ago.midnight.to_time }
            it { subject.first['vv']['m'].should eq 8 }
            it { subject.last['d'].to_time.should eql Time.now.utc.midnight.to_time }
            it { subject.last['vv']['m'].should eq 12 }
          end
        end
      end

      describe ":stats" do
        describe "accepts an ActiveRecord::Relation" do
          subject { described_class.last_stats(stats: described_class.where(t: site1.token), fill_missing_days: false) }

          its(:size) { should eql(2) }
          it { subject.first['d'].to_time.should eql 30.days.ago.midnight.to_time }
          it { subject.first['vv']['m'].should eql(2) }
          it { subject.second['d'].to_time.should eql Time.now.utc.midnight.to_time }
          it { subject.second['vv']['m'].should eql(4) }
        end
      end

      describe ":view_type" do
        describe "defaults to 'vv" do
          subject { described_class.last_stats(token: site1.token, fill_missing_days: false) }

          its(:size) { should eql(2) }
          it { subject.first['vv']['m'].should eql(2) }
          it { subject.second['vv']['m'].should eql(4) }
        end

        describe "accepts 'pv'" do
          subject { described_class.last_stats(token: site1.token, view_type: 'pv', fill_missing_days: false) }

          its(:size) { should eql(2) }
          it { subject.first['pv']['e'].should eql(1) }
          it { subject.second['pv']['e'].should eql(3) }
        end
      end

      describe ":from & :to" do
        subject { described_class.last_stats(token: site1.token, from: 2.days.ago.midnight, to: Time.now.utc.midnight, fill_missing_days: false) }

        its(:size) { should eql(1) }
        it { subject.first['d'].to_time.should eql Time.now.utc.midnight.to_time }
        it { subject.first['vv']['m'].should eql(4) }
      end

      describe ":fill_missing_days" do
        describe "defaults to true" do
          subject { described_class.last_stats(token: site1.token, from: 30.days.ago.midnight, to: 1.day.ago.midnight) }

          its(:size) { should eql(30) }
          it { subject.first['d'].to_time.should eql 30.days.ago.midnight.to_time }
          it { subject.first['vv']['m'].should eql(2) }
          it { subject[29]['d'].to_time.should eql 1.day.ago.midnight.to_time }
          it { subject[29]['vv']['m'].should eql(0) }
        end

        describe "accepts a boolean" do
          subject { described_class.last_stats(token: site1.token, fill_missing_days: false, from: 30.days.ago.midnight, to: 1.day.ago.midnight) }

          its(:size) { should eql(1) }
          it { subject.first['d'].to_time.should eql 30.days.ago.midnight.to_time }
          it { subject.first['vv']['m'].should eql(2) }
        end

        describe "accepts an integer" do
          subject { described_class.last_stats(token: site1.token, fill_missing_days: 3, from: 30.days.ago.midnight, to: 1.day.ago.midnight) }

          its(:size) { should eql(30) }
          it { subject.first['d'].to_time.should eql 30.days.ago.midnight.to_time }
          it { subject.first['vv']['m'].should eql(2) }
          it { subject.last['d'].to_time.should eql 1.day.ago.midnight.to_time }
          it { subject.last['vv']['m'].should eql(3) }
        end
      end
    end
  end
end
