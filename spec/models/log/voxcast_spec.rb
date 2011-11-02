require 'spec_helper'

describe Log::Voxcast do

  context "Factory build" do
    use_vcr_cassette "ogone/one_log"
    subject { FactoryGirl.build(:log_voxcast, :name => 'cdn.sublimevideo.net.log.1274773200-1274773260.gz') }

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
        FactoryGirl.create(:log_voxcast)
        log = FactoryGirl.build(:log_voxcast)
        log.should_not be_valid
        log.should have(1).error_on(:name)
      end
    end
  end

  context "Factory create" do
    use_vcr_cassette "ogone/one_saved_log"
    subject { FactoryGirl.create(:log_voxcast) }

    its(:created_at) { should be_present }
    its(:hostname)   { should == 'cdn.sublimevideo.net' }
    its("file.url")  { should == "/uploads/voxcast/cdn.sublimevideo.net.log.1275002700-1275002760.gz" }
    its("file.size") { should == 1149 }

    it "should have good log content" do
      log = Log::Voxcast.find(subject.id) # to be sure that log is well saved with CarrierWave
      Zlib::GzipReader.open(log.file.path) do |gz|
        gz.read.should include("#Fields: x-cachemiss x-cachestatus")
      end
    end

    it "should parse and create usages from trackers on parse" do
      SiteUsage.should_receive(:create_usages_from_trackers!)
      Log::Voxcast.parse_log(subject.id)
    end

    it "should set parsed_at on parse" do
      SiteUsage.stub(:create_usages_from_trackers!)
      Log::Voxcast.parse_log(subject.id)
      subject.reload.parsed_at.should >= subject.created_at
    end

    it "should delay parse_log && parse_log_referrer after create" do
      subject # trigger log creation
      jobs = Delayed::Job.all.sort_by { |j| j.priority }
      jobs[0].name.should == 'Class#parse_log_for_stats'
      jobs[1].name.should == 'Class#parse_log'
      jobs[2].name.should == 'Class#parse_log_for_video_tags'
      jobs[3].name.should == 'Class#parse_log_for_referrers'
      jobs[4].name.should == 'Class#parse_log_for_user_agents'
    end
  end

  context "Factory from 4076.voxcdn.com" do
    before(:each) do
      VoxcastCDN.stub(:download_log).with('4076.voxcdn.com.log.1279103340-1279103400.gz') {
        File.new(Rails.root.join('spec/fixtures/logs/voxcast/4076.voxcdn.com.log.1279103340-1279103400.gz'))
      }
    end
    subject { FactoryGirl.create(:log_voxcast, :name => '4076.voxcdn.com.log.1279103340-1279103400.gz') }

    its(:created_at) { should be_present }
    its(:hostname)   { should == '4076.voxcdn.com' }
    its("file.url")  { should == "/uploads/voxcast/4076.voxcdn.com.log.1279103340-1279103400.gz" }
    its("file.size") { should == 848 }

    it "should have good log content" do
      log = Log::Voxcast.find(subject.id) # to be sure that log is well saved with CarrierWave
      Zlib::GzipReader.open(log.file.path) do |gz|
        gz.read.should include("#Fields: x-cachemiss x-cachestatus")
      end
    end

    it "should parse and create usages from trackers on parse" do
      SiteUsage.should_receive(:create_usages_from_trackers!)
      Log::Voxcast.parse_log(subject.id)
    end

    it "should set parsed_at on parse" do
      SiteUsage.stub(:create_usages_from_trackers!)
      Log::Voxcast.parse_log(subject.id)
      subject.reload.parsed_at.should >= subject.created_at
    end

    it "should delay parse_log after create" do
      subject # trigger log creation
      Delayed::Job.all.should have(5).job
    end
  end

  describe "Class Methods" do

    describe ".download_and_create_new_logs" do
      it "launches download_and_create_new_non_ssl_logs && download_and_create_new_ssl_logs if not already launched" do
        Log::Voxcast.should_receive(:download_and_create_new_non_ssl_logs)
        Log::Voxcast.should_receive(:download_and_create_new_ssl_logs)
        Log::Voxcast.download_and_create_new_logs
      end

      it "not launches download_and_create_new_non_ssl_logs && download_and_create_new_ssl_logs if already launched" do
        VCR.use_cassette("voxcast/download_and_create_new_logs") do
          Log::Voxcast.download_and_create_new_logs
        end
        Log::Voxcast.should_not_receive(:download_and_create_new_non_ssl_logs)
        Log::Voxcast.should_not_receive(:download_and_create_new_ssl_logs)
        Log::Voxcast.download_and_create_new_logs
      end
    end

    describe ".download_and_create_new_non_ssl_logs" do
      it "calls download_and_create_new_logs methods with the non ssl voxcast hostname" do
        Log::Voxcast.should_receive(:download_and_create_new_logs_and_redelay).with("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs)
        Log::Voxcast.download_and_create_new_non_ssl_logs
      end
    end
    describe ".download_and_create_new_ssl_logs" do
      it "calls download_and_create_new_logs methods with the ssl voxcast hostname" do
        Log::Voxcast.should_receive(:download_and_create_new_logs_and_redelay).with("4076.voxcdn.com", :download_and_create_new_ssl_logs)
        Log::Voxcast.download_and_create_new_ssl_logs
      end
    end

    describe ".download_and_create_new_logs_and_redelay" do
      context "with no log saved" do
        use_vcr_cassette "voxcast/download_and_create_new_logs_and_redelay 0 logs"

        it "creates 1 log" do
          expect { Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs) }.to change(Log::Voxcast, :count).by(1)
        end
        it "delays method to run in 1 min" do
          Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs)
          Delayed::Job.last.run_at.should eq 1.minute.from_now.change(sec: 0)
        end
      end

      context "with a log saved" do
        use_vcr_cassette "voxcast/download_and_create_new_logs_and_redelay 1 min ago"
        before(:each) do
          FactoryGirl.create(:log_voxcast, :name => Log::Voxcast.log_name("cdn.sublimevideo.net", Time.now.change(sec: 0)))
        end

        it "creates 0 log (no duplicates)" do
          expect { Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs) }.to_not change(Log::Voxcast, :count)
        end
        it "delays method to run in 1 min" do
          Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs)
          Delayed::Job.last.handler.should match "download_and_create_new_non_ssl_logs"
          Delayed::Job.last.run_at.should eq 1.minute.from_now.change(sec: 0)
        end
      end

      context "with log saved 1 min ago" do
        use_vcr_cassette "voxcast/download_and_create_new_logs_and_redelay 1 min ago"
        before(:each) do
          FactoryGirl.create(:log_voxcast, :name => Log::Voxcast.log_name("cdn.sublimevideo.net", 1.minute.ago.change(sec: 0)))
        end

        it "creates 1 log" do
          expect { Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs) }.to change(Log::Voxcast, :count).by(1)
        end
        it "delays method to run in 1 min" do
          Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs)
          Delayed::Job.last.handler.should match "download_and_create_new_non_ssl_logs"
          Delayed::Job.last.run_at.should eq 1.minute.from_now.change(sec: 0)
        end
      end

      context "with log saved 5 min ago" do
        use_vcr_cassette "voxcast/download_and_create_new_logs_and_redelay 5 min ago"
        before(:each) do
          FactoryGirl.create(:log_voxcast, :name => Log::Voxcast.log_name("cdn.sublimevideo.net", 5.minutes.ago.change(sec: 0)))
        end

        it "creates 5 logs" do
          expect { Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs) }.to change(Log::Voxcast, :count).by(5)
        end
        it "delays method to run in 1 min" do
          Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs)
          Delayed::Job.last.handler.should match "download_and_create_new_non_ssl_logs"
          Delayed::Job.last.run_at.should eq 1.minute.from_now.change(sec: 0)
        end
      end

      # context "with a log that is not uploaded to S3" do
      #   use_vcr_cassette "voxcast/download_and_create_new_logs_and_redelay 0 logs"
      #   before(:each) do
      #     Log::Voxcast.stub(:create!) { raise Aws::AwsError }
      #   end
      #
      #   it "doesn't save the record" do
      #     logs_count = Log::Voxcast.count
      #     expect { Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs) }.to raise_error(Aws::AwsError)
      #     Log::Voxcast.count.should eql logs_count
      #   end
      #
      #   it "raises exception" do
      #     expect { Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs) }.to raise_error(Aws::AwsError)
      #   end
      #
      #   # it "delays method to run now anyway" do
      #   #   expect { Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs) }.to raise_error(Aws::AwsError)
      #   #   Delayed::Job.last.handler.should match "download_and_create_new_non_ssl_logs"
      #   #   Delayed::Job.last.run_at.should eq Time.now.utc.change(sec: 0)
      #   # end
      # end
    end

    describe ".log_name" do
      specify { Log::Voxcast.log_name('cdn.sublimevideo.net', Time.utc(2011,7,7,11,37)).should eq 'cdn.sublimevideo.net.log.1310038560-1310038620.gz' }
    end

    describe ".next_log_ended_at" do
      context "with no logs saved" do
        specify { Log::Voxcast.next_log_ended_at('cdn.sublimevideo.net').should eq Time.now.utc.change(sec: 0) }
      end

      context "with already a log saved" do
        use_vcr_cassette "voxcast/next_log_ended_at"
        before(:each) do
          FactoryGirl.create(:log_voxcast, :name => "cdn.sublimevideo.net.log.#{Time.utc(2011,7,7,9,29).to_i}-#{Time.utc(2011,7,7,9,30).to_i}.gz")
          FactoryGirl.create(:log_voxcast, :name => "cdn.sublimevideo.net.log.#{Time.utc(2011,7,7,9,37).to_i}-#{Time.utc(2011,7,7,9,38).to_i}.gz")
        end

        it "should check the last log created if no last_log_ended_at is given" do
          Log::Voxcast.next_log_ended_at('cdn.sublimevideo.net').should eq Time.utc(2011,7,7,9,39)
        end

        it "should just add 60 seconds when last_log_ended_at is given" do
          Log::Voxcast.next_log_ended_at('cdn.sublimevideo.net', Time.utc(2011,7,7,11,0)).should eq Time.utc(2011,7,7,11,1)
        end
      end
    end

    it "should have config values" do
      Log::Voxcast.config.should == {
        :file_format_class_name => "LogsFileFormat::VoxcastSites",
        :store_dir => "voxcast"
      }
    end

    describe ".parse_log_for_stats" do
      before(:each) do
        log_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1284549900-1284549960.gz'))
        VoxcastCDN.stub(:download_log).with('cdn.sublimevideo.net.log.1284549900-1284549960.gz') { log_file }
        @log = Factory(:log_voxcast, :name => 'cdn.sublimevideo.net.log.1284549900-1284549960.gz')
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
    before(:each) do
      log_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1284549900-1284549960.gz'))
      VoxcastCDN.stub(:download_log).with('cdn.sublimevideo.net.log.1284549900-1284549960.gz') { log_file }
      @log = FactoryGirl.create(:log_voxcast, :name => 'cdn.sublimevideo.net.log.1284549900-1284549960.gz')
    end

    describe "#parse_and_create_stats!" do
      it "analyzes logs" do
        VoxcastCDN.should_not_receive(:download_log)
        LogAnalyzer.should_receive(:parse).with(an_instance_of(File), 'LogsFileFormat::VoxcastStats')
        Stat.should_receive(:create_stats_from_trackers!)
        @log.parse_and_create_stats!
      end
    end
    describe "#parse_and_create_referrers!" do
      it "analyzes logs" do
        VoxcastCDN.should_not_receive(:download_log)
        LogAnalyzer.should_receive(:parse).with(an_instance_of(File), 'LogsFileFormat::VoxcastReferrers')
        Referrer.should_receive(:create_or_update_from_trackers!)
        @log.parse_and_create_referrers!
      end
    end
    describe "#parse_and_create_user_agents!" do
      it "analyzes logs" do
        VoxcastCDN.should_not_receive(:download_log)
        LogAnalyzer.should_receive(:parse).with(an_instance_of(File), 'LogsFileFormat::VoxcastUserAgents')
        UsrAgent.should_receive(:create_or_update_from_trackers!)
        @log.parse_and_create_user_agents!
      end
    end
    describe "#parse_and_create_video_tags!" do
      it "analyzes logs" do
        VoxcastCDN.should_not_receive(:download_log)
        LogAnalyzer.should_receive(:parse).with(an_instance_of(File), 'LogsFileFormat::VoxcastVideoTags')
        VideoTag.should_receive(:create_or_update_from_trackers!)
        @log.parse_and_create_video_tags!
      end
    end

    describe "minute / hour / day / month" do
      subject { Factory.build(:log_voxcast, :name => 'cdn.sublimevideo.net.log.1284549900-1284549960.gz') }

      its(:minute) { should eql Time.utc(2010, 9, 15, 11, 25) }
      its(:hour)   { should eql Time.utc(2010, 9, 15, 11) }
      its(:day)    { should eql Time.utc(2010, 9, 15) }
      its(:month)  { should eql Time.utc(2010, 9, 1) }
    end

  end

end
