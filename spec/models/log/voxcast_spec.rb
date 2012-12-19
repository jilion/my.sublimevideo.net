require 'spec_helper'

describe Log::Voxcast do
  let(:log_file) { fixture_file('logs/voxcast/4076.voxcdn.com.log.1279103340-1279103400.gz') }

  context "Factory build" do
    use_vcr_cassette "ogone/one_log"
    subject { build(:log_voxcast, name: 'cdn.sublimevideo.net.log.1274773200-1274773260.gz', file: log_file) }

    its(:hostname)   { should == 'cdn.sublimevideo.net' }
    its(:started_at) { should == Time.zone.at(1274773200).utc }
    its(:ended_at)   { should == Time.zone.at(1274773260).utc }

    its(:parsed_at)             { should be_nil}
    its(:stats_parsed_at)       { should be_nil}
    its(:referrers_parsed_at)   { should be_nil}
    its(:user_agents_parsed_at) { should be_nil}
    its(:video_tags_parsed_at) { should be_nil}
    it { should be_valid }
  end

  describe "Validations" do
    context "with already the same log in db" do
      use_vcr_cassette "ogone/one_saved_log"

      it "should validate uniqueness of name" do
        create(:log_voxcast, file: log_file)
        log = build(:log_voxcast)
        log.should_not be_valid
        log.should have(1).error_on(:name)
      end
    end
  end

  context "Factory create" do
    use_vcr_cassette "ogone/one_saved_log"
    subject { create(:log_voxcast, file: log_file) }

    its(:created_at) { should be_present }
    its(:hostname)   { should == 'cdn.sublimevideo.net' }
    its("file.url")  { should == "/uploads/voxcast/cdn.sublimevideo.net.log.1275002700-1275002760.gz" }
    its("file.size") { should == 848 }

    it "should have good log content" do
      log = Log::Voxcast.find(subject.id) # to be sure that log is well saved with CarrierWave
      Zlib::GzipReader.open(log.file.path) do |gz|
        gz.read.should include("#Fields: x-cachemiss x-cachestatus")
      end
    end

    it "should parse and create usages from trackers on parse" do
      SiteUsage.should_receive(:create_usages_from_trackers!)
      described_class.parse_log(subject.id)
    end

    it "should set parsed_at on parse" do
      SiteUsage.stub(:create_usages_from_trackers!)
      described_class.parse_log(subject.id)
      subject.reload.parsed_at.should >= subject.created_at
    end

    it "should delay parse_log methods after create" do
      described_class.should delay(:parse_log_for_stats, queue: 'log_high', at: 5.seconds.from_now.to_i).with('log_id')
      described_class.should delay(:parse_log_for_video_tags, queue: 'log_high', at: 5.seconds.from_now.to_i).with('log_id')
      described_class.should delay(:parse_log, queue: 'log', at: 10.seconds.from_now.to_i).with('log_id')
      described_class.should delay(:parse_log_for_user_agents, queue: 'log', at: 10.seconds.from_now.to_i).with('log_id')
      described_class.should delay(:parse_log_for_referrers, queue: 'log', at: 10.seconds.from_now.to_i).with('log_id')
      create(:log_voxcast, id: 'log_id', file: log_file)
    end
  end

  context "Factory from 4076.voxcdn.com" do
    subject { create(:log_voxcast, name: '4076.voxcdn.com.log.1279103340-1279103400.gz', file: log_file) }

    its(:created_at) { should be_present }
    its(:hostname)   { should == '4076.voxcdn.com' }
    its("file.url")  { should == "/uploads/voxcast/4076.voxcdn.com.log.1279103340-1279103400.gz" }
    its("file.size") { should == 848 }

    it "should have good log content" do
      log = described_class.find(subject.id) # to be sure that log is well saved with CarrierWave
      Zlib::GzipReader.open(log.file.path) do |gz|
        gz.read.should include("#Fields: x-cachemiss x-cachestatus")
      end
    end

    it "should parse and create usages from trackers on parse" do
      SiteUsage.should_receive(:create_usages_from_trackers!)
      described_class.parse_log(subject.id)
    end

    it "should set parsed_at on parse" do
      SiteUsage.stub(:create_usages_from_trackers!)
      described_class.parse_log(subject.id)
      subject.reload.parsed_at.should >= subject.created_at
    end

    it "should delay parse_log methods after create" do
      described_class.should delay(:parse_log_for_stats, queue: 'log_high', at: 5.seconds.from_now.to_i).with('log_id')
      described_class.should delay(:parse_log_for_video_tags, queue: 'log_high', at: 5.seconds.from_now.to_i).with('log_id')
      described_class.should delay(:parse_log, queue: 'log', at: 10.seconds.from_now.to_i).with('log_id')
      described_class.should delay(:parse_log_for_user_agents, queue: 'log', at: 10.seconds.from_now.to_i).with('log_id')
      described_class.should delay(:parse_log_for_referrers, queue: 'log', at: 10.seconds.from_now.to_i).with('log_id')
      create(:log_voxcast, name: '4076.voxcdn.com.log.1279103340-1279103400.gz', id: 'log_id', file: log_file)
    end
  end

  describe "Class Methods" do

    describe ".download_and_create_new_logs" do
      context "with no log saved" do
        use_vcr_cassette "voxcast/download_and_create_new_logs 0 logs"

        it "creates 1 log" do
          expect { Log::Voxcast.download_and_create_new_logs }.to change(Log::Voxcast, :count).by(1)
        end
      end

      context "with a log saved" do
        use_vcr_cassette "voxcast/download_and_create_new_logs 1 min ago"
        let(:log_voxcast) { create(:log_voxcast, name: Log::Voxcast.log_filename(Time.now.change(sec: 0)), file: log_file) }

        it "creates 0 log (no duplicates)" do
          Timecop.freeze Time.now do
            log_voxcast
            expect { Log::Voxcast.download_and_create_new_logs }.to_not change(Log::Voxcast, :count)
          end
        end
      end

      context "with log saved 1 min ago" do
        use_vcr_cassette "voxcast/download_and_create_new_logs 1 min ago"
        let(:log_voxcast) { create(:log_voxcast, name: Log::Voxcast.log_filename(1.minute.ago.change(sec: 0)), file: log_file) }

        it "creates 1 log" do
          Timecop.freeze Time.now do
            log_voxcast
            expect { Log::Voxcast.download_and_create_new_logs }.to change(Log::Voxcast, :count).by(1)
          end
        end
      end

      context "with log saved 5 min ago"  do
        use_vcr_cassette "voxcast/download_and_create_new_logs 5 min ago"
        let(:log_voxcast) { create(:log_voxcast, name: Log::Voxcast.log_filename(5.minutes.ago.change(sec: 0)), file: log_file) }

        it "creates 5 logs" do
          Timecop.freeze Time.now do
            log_voxcast
            expect { Log::Voxcast.download_and_create_new_logs }.to change(Log::Voxcast, :count).by(5)
          end
        end
      end
    end

    describe ".log_filename" do
      specify { Log::Voxcast.log_filename(Time.utc(2011,7,7,11,37)).should eq '4076.voxcdn.com.log.1310038560-1310038620.gz' }
    end

    describe ".next_ended_at" do
      context "with no logs saved" do
        specify { Log::Voxcast.next_ended_at.should eq Time.now.utc.change(sec: 0) }
      end

      context "with already a log saved" do
        use_vcr_cassette "voxcast/next_log_ended_at"
        before do
          create(:log_voxcast, name: "4076.voxcdn.com.log.#{Time.utc(2011,7,7,9,29).to_i}-#{Time.utc(2011,7,7,9,30).to_i}.gz", file: log_file)
          create(:log_voxcast, name: "4076.voxcdn.com.log.#{Time.utc(2011,7,7,9,37).to_i}-#{Time.utc(2011,7,7,9,38).to_i}.gz", file: log_file)
        end

        it "should check the last log created if no last_log_ended_at is given" do
          Log::Voxcast.next_ended_at.should eq Time.utc(2011,7,7,9,39)
        end
      end
    end

    it "should have config values" do
      Log::Voxcast.config.should == {
        file_format_class_name: "LogsFileFormat::VoxcastSites",
        store_dir: "voxcast"
      }
    end

    describe ".parse_log_for_stats" do
      before do
        log_file = fixture_file('logs/voxcast/cdn.sublimevideo.net.log.1284549900-1284549960.gz')
        CDN::VoxcastWrapper.stub(:download_log).with('cdn.sublimevideo.net.log.1284549900-1284549960.gz') { log_file }
        @log = create(:log_voxcast, name: 'cdn.sublimevideo.net.log.1284549900-1284549960.gz', file: log_file)
      end

      it "call parse_and_create_stats! and set stats_parsed_at" do
        Log::Voxcast.stub(:find) { @log }
        @log.should_receive(:parse_and_create_stats!)
        Log::Voxcast.parse_log_for_stats(@log.id)
        @log.reload.stats_parsed_at.should be_present
      end

      it "does nothing if stats_parsed_at already set" do
        @log.update_attribute(:stats_parsed_at, Time.now.utc)
        Log::Voxcast.stub(:find) { @log }
        @log.should_not_receive(:parse_and_referrers_stats!)
        Log::Voxcast.parse_log_for_stats(@log.id)
      end
    end
  end

  describe "Instance Methods" do
    let(:log_file) { fixture_file('logs/voxcast/cdn.sublimevideo.net.log.1284549900-1284549960.gz') }
    before do
      CDN::VoxcastWrapper.stub(:download_log).with('cdn.sublimevideo.net.log.1284549900-1284549960.gz') { log_file }
      @log = create(:log_voxcast, name: 'cdn.sublimevideo.net.log.1284549900-1284549960.gz', file: log_file)
    end

    describe "#parse_and_create_stats!" do
      it "analyzes logs" do
        CDN::VoxcastWrapper.should_not_receive(:download_log)
        LogAnalyzer.should_receive(:parse).with(an_instance_of(Tempfile), 'LogsFileFormat::VoxcastStats')
        Stat.should_receive(:create_stats_from_trackers!)
        @log.parse_and_create_stats!
      end
    end
    describe "#parse_and_create_referrers!" do
      it "analyzes logs" do
        CDN::VoxcastWrapper.should_not_receive(:download_log)
        LogAnalyzer.should_receive(:parse).with(an_instance_of(Tempfile), 'LogsFileFormat::VoxcastReferrers')
        Referrer.should_receive(:create_or_update_from_trackers!)
        @log.parse_and_create_referrers!
      end
    end
    describe "#parse_and_create_user_agents!" do
      it "analyzes logs" do
        CDN::VoxcastWrapper.should_not_receive(:download_log)
        LogAnalyzer.should_receive(:parse).with(an_instance_of(Tempfile), 'LogsFileFormat::VoxcastUserAgents')
        UsrAgent.should_receive(:create_or_update_from_trackers!)
        @log.parse_and_create_user_agents!
      end
    end
    describe "#parse_and_create_video_tags!" do
      let(:video_tags_data) { { ['site_token', 'uid'] => { 'video' => 'data' } } }

      it "analyzes logs" do
        video_tags_trackers = stub
        @log.should_receive(:trackers).with('LogsFileFormat::VoxcastVideoTags', title: :video_tags) { video_tags_trackers }
        VideoTagTrackersParser.should_receive(:extract_video_tags_data).with(video_tags_trackers) { video_tags_data }
        VideoTagUpdater.should delay(:update).with('site_token', 'uid', { 'video' => 'data' })
        @log.parse_and_create_video_tags!
      end

      context "with utf-8 complex logs" do
        let(:log_file) { fixture_file('logs/voxcast/4076.voxcdn.com.log.1355880780-1355880840.gz') }

        it "analyzes logs" do
          @log.parse_and_create_video_tags!
        end
      end
    end

    describe "minute / hour / day / month" do
      subject { build(:log_voxcast, name: 'cdn.sublimevideo.net.log.1284549900-1284549960.gz') }

      its(:minute) { should eql Time.utc(2010, 9, 15, 11, 25) }
      its(:hour)   { should eql Time.utc(2010, 9, 15, 11) }
      its(:day)    { should eql Time.utc(2010, 9, 15) }
      its(:month)  { should eql Time.utc(2010, 9, 1) }
    end

  end

end
