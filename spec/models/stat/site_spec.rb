require 'spec_helper'

describe Stat::Site do

  # describe "Scopes:" do
  #
  #   describe ".last_days" do
  #     before(:all) do
  #       @site = Factory.create(:site)
  #     end
  #
  #     before(:each) do
  #       Factory.create(:site_stat, t: @site.token, d: 30.days.ago.change(hour: 0, min: 0, sec: 0), pv: {e: 101})
  #       Factory.create(:site_stat, t: @site.token, d: Time.now.utc.change(hour: 0, min: 0, sec: 0), pv: {e: 103})
  #     end
  #
  #     describe "otpions" do
  #       describe ":days" do
  #         describe "defaults to 30 days" do
  #           subject { described_class.last_days(@site.token) }
  #
  #           its(:size) { should eql(30) }
  #           it { subject.first.d.to_time.should eql 30.days.ago.midnight.to_time }
  #           it { subject.first.billable_pv.should eql(101) }
  #           it { subject[29].d.to_time.should eql 1.day.ago.midnight.to_time }
  #           it { subject[29].billable_pv.should eql(0) }
  #         end
  #
  #         describe "accepts an integer" do
  #           subject { described_class.last_days(@site.token, days: 2) }
  #
  #           its(:size) { should eql(2) }
  #           it { subject.first.d.to_time.should eql 2.days.ago.midnight.to_time }
  #           it { subject.first.billable_pv.should eql(0) }
  #           it { subject.second.d.to_time.should eql 1.day.ago.midnight.to_time }
  #           it { subject.second.billable_pv.should eql(0) }
  #         end
  #       end
  #
  #       describe ":fill_missing_days" do
  #         describe "defaults to true" do
  #           subject { described_class.last_days(@site.token, days: 30) }
  #
  #           its(:size) { should eql(30) }
  #           it { subject.first.d.to_time.should eql 30.days.ago.midnight.to_time }
  #           it { subject.first.billable_pv.should eql(101) }
  #           it { subject[29].d.to_time.should eql 1.day.ago.midnight.to_time }
  #           it { subject[29].billable_pv.should eql(0) }
  #         end
  #
  #         describe "accepts a boolean" do
  #           subject { described_class.last_days(@site.token, days: 30, fill_missing_days: false) }
  #
  #           its(:size) { should eql(1) }
  #           it { subject.first.d.to_time.should eql 30.days.ago.midnight.to_time }
  #           it { subject.first.billable_pv.should eql(101) }
  #         end
  #
  #         describe "accepts an integer" do
  #           subject { described_class.last_days(@site.token, days: 30, fill_missing_days: 3) }
  #
  #           its(:size) { should eql(30) }
  #           it { subject.first.d.to_time.should eql 30.days.ago.midnight.to_time }
  #           it { subject.first.billable_pv.should eql(101) }
  #           it { subject[29].d.to_time.should eql 1.day.ago.midnight.to_time }
  #           it { subject[29].billable_pv.should eql(3) }
  #         end
  #       end
  #     end
  #   end
  #
  #   describe ".json" do
  #     before(:all) do
  #       @site = Factory.create(:site)
  #     end
  #
  #     before(:each) do
  #       @second = Time.now.utc.change(usec: 0)
  #       Factory.create(:site_stat, t: @site.token, s: (@second - 61.seconds), pv: {e: 1})
  #       Factory.create(:site_stat, t: @site.token, s: (@second - 60.seconds), pv: {e: 2})
  #       Factory.create(:site_stat, t: @site.token, s: (@second - 59.seconds), pv: {e: 3})
  #       Factory.create(:site_stat, t: @site.token, s: (@second - 1.second), pv: {e: 4})
  #       Factory.create(:site_stat, t: @site.token, s: @second, pv: {e: 5})
  #
  #       Factory.create(:site_stat, t: @site.token, m: 60.minutes.ago.change(sec: 0), pv: {e: 2})
  #       Factory.create(:site_stat, t: @site.token, m: 59.minutes.ago.change(sec: 0), pv: {e: 3})
  #       Factory.create(:site_stat, t: @site.token, m: 1.minute.ago.change(sec: 0), pv: {e: 4})
  #       Factory.create(:site_stat, t: @site.token, m: Time.now.utc.change(sec: 0), pv: {e: 5})
  #
  #       Factory.create(:site_stat, t: @site.token, h: 24.hours.ago.change(min: 0, sec: 0), pv: {e: 47})
  #       Factory.create(:site_stat, t: @site.token, h: 23.hours.ago.change(min: 0, sec: 0), pv: {e: 48})
  #       Factory.create(:site_stat, t: @site.token, h: 1.hours.ago.change(min: 0, sec: 0), pv: {e: 49})
  #       Factory.create(:site_stat, t: @site.token, h: Time.now.utc.change(min: 0, sec: 0), pv: {e: 50})
  #
  #       @day400 = Factory.create(:site_stat, t: @site.token, d: 400.days.ago.change(hour: 0, min: 0, sec: 0), pv: {e: 100})
  #       Factory.create(:site_stat, t: @site.token, d: 3.days.ago.change(hour: 0, min: 0, sec: 0), pv: {e: 101})
  #       Factory.create(:site_stat, t: @site.token, d: 1.day.ago.change(hour: 0, min: 0, sec: 0), pv: {e: 102})
  #       Factory.create(:site_stat, t: @site.token, d: Time.now.utc.change(hour: 0, min: 0, sec: 0), pv: {e: 103})
  #     end
  #
  #     describe "with seconds period" do
  #       subject { JSON.parse(SiteStat.json(@site.token, 'seconds')) }
  #       before(:each) { Timecop.travel(@second) }
  #
  #       its(:size) { should eql(61) }
  #       it { subject[0]['pv'].should eql(2) }
  #       it { subject[1]['pv'].should eql(3) }
  #       it { subject[58]['pv'].should eql(nil) }
  #       it { subject[59]['pv'].should eql(4) }
  #       it { subject[60]['pv'].should eql(5) }
  #
  #       it { subject[0]['id'].should eql((@second - 60.seconds).to_i) }
  #       it { subject[1]['id'].should eql((@second - 59.seconds).to_i) }
  #       it { subject[60]['id'].should eql(@second.to_i) }
  #     end
  #
  #     describe "with minutes period" do
  #       subject { JSON.parse(SiteStat.json(@site.token, 'minutes')) }
  #
  #       its(:size) { should eql(60) }
  #       it { subject[0]['pv'].should eql(3) }
  #       it { subject[1]['pv'].should eql(nil) }
  #       it { subject[58]['pv'].should eql(4) }
  #       it { subject[59]['pv'].should eql(5) }
  #
  #       it { subject[0]['id'].should eql(59.minutes.ago.change(sec: 0).to_i) }
  #       it { subject[1]['id'].should eql(58.minutes.ago.change(sec: 0).to_i) }
  #       it { subject[59]['id'].should eql(Time.now.utc.change(sec: 0).to_i) }
  #     end
  #
  #     describe "with hours period" do
  #       subject { JSON.parse(SiteStat.json(@site.token, 'hours')) }
  #
  #       its(:size) { should eql(24) }
  #       it { subject[0]['pv'].should eql(47) }
  #       it { subject[1]['pv'].should eql(48) }
  #       it { subject[2]['pv'].should eql(nil) }
  #       it { subject[23]['pv'].should eql(49) }
  #
  #       it { subject[0]['id'].should eql(24.hours.ago.change(min: 0, sec: 0).to_i) }
  #       it { subject[2]['id'].should eql(22.hours.ago.change(min: 0, sec: 0).to_i) }
  #       it { subject[23]['id'].should eql(1.hours.ago.change(min: 0, sec: 0).to_i) }
  #     end
  #
  #     describe "with days period" do
  #       subject { JSON.parse(SiteStat.json(@site.token, 'days')) }
  #
  #       its(:size) { should eql(400) }
  #       it { subject[0]['pv'].should eql(100) }
  #       it { subject[1]['pv'].should eql(nil) }
  #       it { subject[397]['pv'].should eql(101) }
  #       it { subject[399]['pv'].should eql(102) }
  #       it { subject[0]['id'].should eql(400.days.ago.change(hour: 0, min: 0, sec: 0).to_i) }
  #       it { subject[1]['id'].should eql(399.days.ago.change(hour: 0, min: 0, sec: 0).to_i) }
  #       it { subject[399]['id'].should eql(1.days.ago.change(hour: 0, min: 0, sec: 0).to_i) }
  #     end
  #
  #     describe "with days period (less than 365 days stats)" do
  #       before(:each) { @day400.delete }
  #       subject { JSON.parse(SiteStat.json(@site.token, 'days')) }
  #
  #       its(:size) { should eql(365) }
  #       it { subject[0]['pv'].should eql(nil) }
  #       it { subject[1]['pv'].should eql(nil) }
  #       it { subject[364]['pv'].should eql(102) }
  #       it { subject[0]['id'].should eql(365.day.ago.change(hour: 0, min: 0, sec: 0).to_i) }
  #       it { subject[364]['id'].should eql(1.day.ago.change(hour: 0, min: 0, sec: 0).to_i) }
  #     end
  #   end
  #
  # end

end
