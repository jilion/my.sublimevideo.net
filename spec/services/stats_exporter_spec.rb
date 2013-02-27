require 'fast_spec_helper'

require 'services/stats_exporter'

unless defined?(ActiveRecord)
  Site              = Class.new
  StatsExport       = Class.new
  StatsExportMailer = Class.new
  VideoTag          = Class.new
  Stat              = Class.new
  Stat::Video       = Class.new
  Stat::Video::Day  = Class.new
end

describe StatsExporter do

  let(:site_token) { 'site_token' }
  let(:site) { mock(Site, token: site_token) }
  let(:from) { 30.days.ago.midnight.to_i }
  let(:to) { 1.days.ago.midnight.to_i }
  let(:stats_exporter) { StatsExporter.new(site_token, from, to) }
  let(:csv_export) { stub }

  before {
    Librato.stub(:increment)
    Site.stub_chain(:where, :first) { site }
  }

  describe "#create_and_notify_export" do

    before do
      StatsExportMailer.stub(:export_ready) { stub('mailer').as_null_object }
      stats_exporter.should_receive(:with_tempfile_csv_export).and_yield(csv_export)
    end

    it "create a StatsExport with the exported csv" do
      StatsExport.should_receive(:create!).with(
        site_token: site_token,
        from: from,
        to: to,
        file: csv_export
      )
      stats_exporter.create_and_notify_export
    end

    it "send a email when export is done" do
      stats_export = stub
      StatsExport.stub(:create!) { stats_export }
      StatsExportMailer.should_receive(:export_ready).with(stats_export) { stub('mailer', deliver!: true) }
      stats_exporter.create_and_notify_export
    end

  end

  describe "#with_tempfile_csv_export" do
    let(:video_tags) { [
      stub(uid: 'uid1', title: 'video1'),
      stub(uid: 'uid2', title: 'video2')
    ] }
    let(:video_stats) { [
      stub(vl: { 'm' => 1, 'e' => 11, 'em' => 101 }, vv: { 'm' => 1, 'e' => 11, 'em' => 101 }),
      stub(vl: { 'm' => 1, 'e' => 11, 'em' => 101 }, vv: { 'm' => 1, 'e' => 11, 'em' => 101 })
    ] }

    it "yield with a csv full of loads/plays" do
      VideoTag.stub(:find_each).and_yield(video_tags[0]).and_yield(video_tags[1])
      Stat::Video::Day.stub_chain(:where, :between).and_return(video_stats)
      stats_exporter.with_tempfile_csv_export do |export|
        export.read.should eq <<-EOF
uid,title,loads_count,views_count,embed_loads_count,embed_views_count
uid1,video1,24,24,202,202
uid2,video2,24,24,202,202
        EOF
      end
    end

    it "yield with a empty" do
      VideoTag.stub(:find_each).and_yield(video_tags[0]).and_yield(video_tags[1])
      Stat::Video::Day.stub_chain(:where, :between).and_return([])
      stats_exporter.with_tempfile_csv_export do |export|
        export.read.should eq <<-EOF
uid,title,loads_count,views_count,embed_loads_count,embed_views_count
uid1,video1,0,0,0,0
uid2,video2,0,0,0,0
        EOF
      end
    end

  end

end
