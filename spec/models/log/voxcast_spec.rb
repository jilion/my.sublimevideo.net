require 'spec_helper'

describe Log::Voxcast do

  context "Factory build" do
    use_vcr_cassette "ogone/one_log"
    subject { Factory.build(:log_voxcast, :name => 'cdn.sublimevideo.net.log.1274773200-1274773260.gz') }

    its(:hostname)   { should == 'cdn.sublimevideo.net' }
    its(:started_at) { should == Time.zone.at(1274773200).utc }
    its(:ended_at)   { should == Time.zone.at(1274773260).utc }

    it { should_not be_parsed }
    it { should_not be_referrers_parsed }
    it { should be_valid }
  end

  describe "Validations" do
    context "with already the same log in db" do
      use_vcr_cassette "ogone/one_saved_log"

      it "should validate uniqueness of name" do
        Factory(:log_voxcast)
        log = Factory.build(:log_voxcast)
        log.should_not be_valid
        log.should have(1).error_on(:name)
      end
    end
  end

  context "Factory create" do
    use_vcr_cassette "ogone/one_saved_log"
    subject { Factory(:log_voxcast) }

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
      jobs = Delayed::Job.all.sort_by { |j| j.name }
      job = jobs.pop
      job.name.should == 'Class#parse_log_for_user_agents'
      job.priority.should == 95
      job = jobs.pop
      job.name.should == 'Class#parse_log_for_referrers'
      job.priority.should == 90
      job = jobs.pop
      job.name.should == 'Class#parse_log'
      job.priority.should == 0
    end
  end

  context "Factory from 4076.voxcdn.com" do
    before(:each) do
      VoxcastCDN.stub(:download_log).with('4076.voxcdn.com.log.1279103340-1279103400.gz') {
        File.new(Rails.root.join('spec/fixtures/logs/voxcast/4076.voxcdn.com.log.1279103340-1279103400.gz'))
      }
    end
    subject { Factory(:log_voxcast, :name => '4076.voxcdn.com.log.1279103340-1279103400.gz') }

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
      Delayed::Job.all.should have(3).job
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
        Log::Voxcast.download_and_create_new_logs
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

        it "creates 0 log" do
          expect { Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs) }.should change(Log::Voxcast, :count).by(0)
        end
        it "delays method to run in 1 min" do
          Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs)
          Delayed::Job.last.run_at.should eq 1.minute.from_now.change(sec: 0)
        end
      end

      context "with log saved 1min ago" do
        use_vcr_cassette "voxcast/download_and_create_new_logs_and_redelay 1 min ago"
        before(:each) do
          Factory(:log_voxcast, :name => Log::Voxcast.log_name("cdn.sublimevideo.net", 1.minute.ago.change(sec: 0)))
        end

        it "creates 1 log" do
          expect { Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs) }.should change(Log::Voxcast, :count).by(1)
        end
        it "delays method to run in 1 min" do
          Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs)
          Delayed::Job.last.run_at.should eq 1.minute.from_now.change(sec: 0)
        end
      end

      context "with log saved 5min ago" do
        use_vcr_cassette "voxcast/download_and_create_new_logs_and_redelay 5 min ago"
        before(:each) do
          Factory(:log_voxcast, :name => Log::Voxcast.log_name("cdn.sublimevideo.net", 5.minutes.ago.change(sec: 0)))
        end

        it "creates 5 logs" do
          expect { Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs) }.should change(Log::Voxcast, :count).by(5)
        end
        it "delays method" do
          Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs)
          Delayed::Job.last.handler.should match "download_and_create_new_non_ssl_logs"
        end
      end

    end

    describe ".log_name" do
      specify { Log::Voxcast.log_name('cdn.sublimevideo.net', Time.utc(2011,7,7,11,37)).should eq 'cdn.sublimevideo.net.log.1310038560-1310038620.gz' }
    end

    describe ".next_log_ended_at" do
      context "with no logs saved" do
        specify { Log::Voxcast.next_log_ended_at('cdn.sublimevideo.net').should eq 1.minute.from_now.change(sec: 0) }
      end

      context "with already a log saved" do
        use_vcr_cassette "voxcast/next_log_ended_at"
        before(:each) do
          Factory(:log_voxcast, :name => "cdn.sublimevideo.net.log.#{Time.utc(2011,7,7,9,29).to_i}-#{Time.utc(2011,7,7,9,30).to_i}.gz")
          Factory(:log_voxcast, :name => "cdn.sublimevideo.net.log.#{Time.utc(2011,7,7,9,37).to_i}-#{Time.utc(2011,7,7,9,38).to_i}.gz")
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
  end

  describe "Instance Methods" do
    before(:each) do
      log_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1284549900-1284549960.gz'))
      VoxcastCDN.stub(:download_log).with('cdn.sublimevideo.net.log.1284549900-1284549960.gz') { log_file }
      @log = Factory(:log_voxcast, :name => 'cdn.sublimevideo.net.log.1284549900-1284549960.gz')
    end

    describe "parse_and_create_referrers!" do
      before(:each) do
        LogAnalyzer.should_receive(:parse)
        Referrer.should_receive(:create_or_update_from_trackers!)
        VoxcastCDN.should_not_receive(:download_log)
        subject.parse_and_create_referrers!
      end

      subject { @log }

      its(:referrers_parsed_at) { should be_present }

      it { should be_referrers_parsed }

      it "should not reparse if already done" do
        Referrer.should_not_receive(:create_or_update_from_trackers!)
        subject.parse_and_create_referrers!
      end
    end

    describe "parse_and_create_user_agents!" do
      before(:each) do
        LogAnalyzer.should_receive(:parse)
        UsrAgent.should_receive(:create_or_update_from_trackers!)
        VoxcastCDN.should_not_receive(:download_log)
        subject.parse_and_create_user_agents!
      end

      subject { @log }

      its(:user_agents_parsed_at) { should be_present }

      it { should be_user_agents_parsed }

      it "should not reparse if already done" do
        UsrAgent.should_not_receive(:create_or_update_from_trackers!)
        subject.parse_and_create_user_agents!
      end
    end
  end

end
require 'spec_helper'

describe Log::Voxcast do

  context "Factory build" do
    use_vcr_cassette "ogone/one_log"
    subject { Factory.build(:log_voxcast, :name => 'cdn.sublimevideo.net.log.1274773200-1274773260.gz') }

    its(:hostname)   { should == 'cdn.sublimevideo.net' }
    its(:started_at) { should == Time.zone.at(1274773200).utc }
    its(:ended_at)   { should == Time.zone.at(1274773260).utc }

    it { should_not be_parsed }
    it { should_not be_referrers_parsed }
    it { should be_valid }
  end

  describe "Validations" do
    context "with already the same log in db" do
      use_vcr_cassette "ogone/one_saved_log"

      it "should validate uniqueness of name" do
        Factory(:log_voxcast)
        log = Factory.build(:log_voxcast)
        log.should_not be_valid
        log.should have(1).error_on(:name)
      end
    end
  end

  context "Factory create" do
    use_vcr_cassette "ogone/one_saved_log"
    subject { Factory(:log_voxcast) }

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
      jobs = Delayed::Job.all.sort_by { |j| j.name }
      job = jobs.pop
      job.name.should == 'Class#parse_log_for_user_agents'
      job.priority.should == 95
      job = jobs.pop
      job.name.should == 'Class#parse_log_for_referrers'
      job.priority.should == 90
      job = jobs.pop
      job.name.should == 'Class#parse_log'
      job.priority.should == 0
    end
  end

  context "Factory from 4076.voxcdn.com" do
    before(:each) do
      VoxcastCDN.stub(:download_log).with('4076.voxcdn.com.log.1279103340-1279103400.gz') {
        File.new(Rails.root.join('spec/fixtures/logs/voxcast/4076.voxcdn.com.log.1279103340-1279103400.gz'))
      }
    end
    subject { Factory(:log_voxcast, :name => '4076.voxcdn.com.log.1279103340-1279103400.gz') }

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
      Delayed::Job.all.should have(3).job
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
        Log::Voxcast.download_and_create_new_logs
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

        it "creates 0 log" do
          expect { Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs) }.should change(Log::Voxcast, :count).by(0)
        end
        it "delays method to run in 1 min" do
          Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs)
          Delayed::Job.last.run_at.should eq 1.minute.from_now.change(sec: 0)
        end
      end

      context "with log saved 1min ago" do
        use_vcr_cassette "voxcast/download_and_create_new_logs_and_redelay 1 min ago"
        before(:each) do
          Factory(:log_voxcast, :name => Log::Voxcast.log_name("cdn.sublimevideo.net", 1.minute.ago.change(sec: 0)))
        end

        it "creates 1 log" do
          expect { Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs) }.should change(Log::Voxcast, :count).by(1)
        end
        it "delays method to run in 1 min" do
          Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs)
          Delayed::Job.last.run_at.should eq 1.minute.from_now.change(sec: 0)
        end
      end

      context "with log saved 5min ago" do
        use_vcr_cassette "voxcast/download_and_create_new_logs_and_redelay 5 min ago"
        before(:each) do
          Factory(:log_voxcast, :name => Log::Voxcast.log_name("cdn.sublimevideo.net", 5.minutes.ago.change(sec: 0)))
        end

        it "creates 5 logs" do
          expect { Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs) }.should change(Log::Voxcast, :count).by(5)
        end
        it "delays method" do
          Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs)
          Delayed::Job.last.handler.should match "download_and_create_new_non_ssl_logs"
        end
      end

    end

    describe ".log_name" do
      specify { Log::Voxcast.log_name('cdn.sublimevideo.net', Time.utc(2011,7,7,11,37)).should eq 'cdn.sublimevideo.net.log.1310038560-1310038620.gz' }
    end

    describe ".next_log_ended_at" do
      context "with no logs saved" do
        specify { Log::Voxcast.next_log_ended_at('cdn.sublimevideo.net').should eq 1.minute.from_now.change(sec: 0) }
      end

      context "with already a log saved" do
        use_vcr_cassette "voxcast/next_log_ended_at"
        before(:each) do
          Factory(:log_voxcast, :name => "cdn.sublimevideo.net.log.#{Time.utc(2011,7,7,9,29).to_i}-#{Time.utc(2011,7,7,9,30).to_i}.gz")
          Factory(:log_voxcast, :name => "cdn.sublimevideo.net.log.#{Time.utc(2011,7,7,9,37).to_i}-#{Time.utc(2011,7,7,9,38).to_i}.gz")
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
  end

  describe "Instance Methods" do
    before(:each) do
      log_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1284549900-1284549960.gz'))
      VoxcastCDN.stub(:download_log).with('cdn.sublimevideo.net.log.1284549900-1284549960.gz') { log_file }
      @log = Factory(:log_voxcast, :name => 'cdn.sublimevideo.net.log.1284549900-1284549960.gz')
    end

    describe "parse_and_create_referrers!" do
      before(:each) do
        LogAnalyzer.should_receive(:parse)
        Referrer.should_receive(:create_or_update_from_trackers!)
        VoxcastCDN.should_not_receive(:download_log)
        subject.parse_and_create_referrers!
      end

      subject { @log }

      its(:referrers_parsed_at) { should be_present }

      it { should be_referrers_parsed }

      it "should not reparse if already done" do
        Referrer.should_not_receive(:create_or_update_from_trackers!)
        subject.parse_and_create_referrers!
      end
    end

    describe "parse_and_create_user_agents!" do
      before(:each) do
        LogAnalyzer.should_receive(:parse)
        UsrAgent.should_receive(:create_or_update_from_trackers!)
        VoxcastCDN.should_not_receive(:download_log)
        subject.parse_and_create_user_agents!
      end

      subject { @log }

      its(:user_agents_parsed_at) { should be_present }

      it { should be_user_agents_parsed }

      it "should not reparse if already done" do
        UsrAgent.should_not_receive(:create_or_update_from_trackers!)
        subject.parse_and_create_user_agents!
      end
    end
  end

end
require 'spec_helper'

describe Log::Voxcast do

  context "Factory build" do
    use_vcr_cassette "ogone/one_log"
    subject { Factory.build(:log_voxcast, :name => 'cdn.sublimevideo.net.log.1274773200-1274773260.gz') }

    its(:hostname)   { should == 'cdn.sublimevideo.net' }
    its(:started_at) { should == Time.zone.at(1274773200).utc }
    its(:ended_at)   { should == Time.zone.at(1274773260).utc }

    it { should_not be_parsed }
    it { should_not be_referrers_parsed }
    it { should be_valid }
  end

  describe "Validations" do
    context "with already the same log in db" do
      use_vcr_cassette "ogone/one_saved_log"

      it "should validate uniqueness of name" do
        Factory(:log_voxcast)
        log = Factory.build(:log_voxcast)
        log.should_not be_valid
        log.should have(1).error_on(:name)
      end
    end
  end

  context "Factory create" do
    use_vcr_cassette "ogone/one_saved_log"
    subject { Factory(:log_voxcast) }

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
      jobs = Delayed::Job.all.sort_by { |j| j.name }
      job = jobs.pop
      job.name.should == 'Class#parse_log_for_user_agents'
      job.priority.should == 95
      job = jobs.pop
      job.name.should == 'Class#parse_log_for_referrers'
      job.priority.should == 90
      job = jobs.pop
      job.name.should == 'Class#parse_log'
      job.priority.should == 0
    end
  end

  context "Factory from 4076.voxcdn.com" do
    before(:each) do
      VoxcastCDN.stub(:download_log).with('4076.voxcdn.com.log.1279103340-1279103400.gz') {
        File.new(Rails.root.join('spec/fixtures/logs/voxcast/4076.voxcdn.com.log.1279103340-1279103400.gz'))
      }
    end
    subject { Factory(:log_voxcast, :name => '4076.voxcdn.com.log.1279103340-1279103400.gz') }

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
      Delayed::Job.all.should have(3).job
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
        Log::Voxcast.download_and_create_new_logs
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

        it "creates 0 log" do
          expect { Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs) }.should change(Log::Voxcast, :count).by(0)
        end
        it "delays method to run in 1 min" do
          Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs)
          Delayed::Job.last.run_at.should eq 1.minute.from_now.change(sec: 0)
        end
      end

      context "with log saved 1min ago" do
        use_vcr_cassette "voxcast/download_and_create_new_logs_and_redelay 1 min ago"
        before(:each) do
          Factory(:log_voxcast, :name => Log::Voxcast.log_name("cdn.sublimevideo.net", 1.minute.ago.change(sec: 0)))
        end

        it "creates 1 log" do
          expect { Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs) }.should change(Log::Voxcast, :count).by(1)
        end
        it "delays method to run in 1 min" do
          Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs)
          Delayed::Job.last.run_at.should eq 1.minute.from_now.change(sec: 0)
        end
      end

      context "with log saved 5min ago" do
        use_vcr_cassette "voxcast/download_and_create_new_logs_and_redelay 5 min ago"
        before(:each) do
          Factory(:log_voxcast, :name => Log::Voxcast.log_name("cdn.sublimevideo.net", 5.minutes.ago.change(sec: 0)))
        end

        it "creates 5 logs" do
          expect { Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs) }.should change(Log::Voxcast, :count).by(5)
        end
        it "delays method" do
          Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs)
          Delayed::Job.last.handler.should match "download_and_create_new_non_ssl_logs"
        end
      end

    end

    describe ".log_name" do
      specify { Log::Voxcast.log_name('cdn.sublimevideo.net', Time.utc(2011,7,7,11,37)).should eq 'cdn.sublimevideo.net.log.1310038560-1310038620.gz' }
    end

    describe ".next_log_ended_at" do
      context "with no logs saved" do
        specify { Log::Voxcast.next_log_ended_at('cdn.sublimevideo.net').should eq 1.minute.from_now.change(sec: 0) }
      end

      context "with already a log saved" do
        use_vcr_cassette "voxcast/next_log_ended_at"
        before(:each) do
          Factory(:log_voxcast, :name => "cdn.sublimevideo.net.log.#{Time.utc(2011,7,7,9,29).to_i}-#{Time.utc(2011,7,7,9,30).to_i}.gz")
          Factory(:log_voxcast, :name => "cdn.sublimevideo.net.log.#{Time.utc(2011,7,7,9,37).to_i}-#{Time.utc(2011,7,7,9,38).to_i}.gz")
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
  end

  describe "Instance Methods" do
    before(:each) do
      log_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1284549900-1284549960.gz'))
      VoxcastCDN.stub(:download_log).with('cdn.sublimevideo.net.log.1284549900-1284549960.gz') { log_file }
      @log = Factory(:log_voxcast, :name => 'cdn.sublimevideo.net.log.1284549900-1284549960.gz')
    end

    describe "parse_and_create_referrers!" do
      before(:each) do
        LogAnalyzer.should_receive(:parse)
        Referrer.should_receive(:create_or_update_from_trackers!)
        VoxcastCDN.should_not_receive(:download_log)
        subject.parse_and_create_referrers!
      end

      subject { @log }

      its(:referrers_parsed_at) { should be_present }

      it { should be_referrers_parsed }

      it "should not reparse if already done" do
        Referrer.should_not_receive(:create_or_update_from_trackers!)
        subject.parse_and_create_referrers!
      end
    end

    describe "parse_and_create_user_agents!" do
      before(:each) do
        LogAnalyzer.should_receive(:parse)
        UsrAgent.should_receive(:create_or_update_from_trackers!)
        VoxcastCDN.should_not_receive(:download_log)
        subject.parse_and_create_user_agents!
      end

      subject { @log }

      its(:user_agents_parsed_at) { should be_present }

      it { should be_user_agents_parsed }

      it "should not reparse if already done" do
        UsrAgent.should_not_receive(:create_or_update_from_trackers!)
        subject.parse_and_create_user_agents!
      end
    end
  end

end
require 'spec_helper'

describe Log::Voxcast do

  context "Factory build" do
    use_vcr_cassette "ogone/one_log"
    subject { Factory.build(:log_voxcast, :name => 'cdn.sublimevideo.net.log.1274773200-1274773260.gz') }

    its(:hostname)   { should == 'cdn.sublimevideo.net' }
    its(:started_at) { should == Time.zone.at(1274773200).utc }
    its(:ended_at)   { should == Time.zone.at(1274773260).utc }

    it { should_not be_parsed }
    it { should_not be_referrers_parsed }
    it { should be_valid }
  end

  describe "Validations" do
    context "with already the same log in db" do
      use_vcr_cassette "ogone/one_saved_log"

      it "should validate uniqueness of name" do
        Factory(:log_voxcast)
        log = Factory.build(:log_voxcast)
        log.should_not be_valid
        log.should have(1).error_on(:name)
      end
    end
  end

  context "Factory create" do
    use_vcr_cassette "ogone/one_saved_log"
    subject { Factory(:log_voxcast) }

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
      jobs = Delayed::Job.all.sort_by { |j| j.name }
      job = jobs.pop
      job.name.should == 'Class#parse_log_for_user_agents'
      job.priority.should == 95
      job = jobs.pop
      job.name.should == 'Class#parse_log_for_referrers'
      job.priority.should == 90
      job = jobs.pop
      job.name.should == 'Class#parse_log'
      job.priority.should == 0
    end
  end

  context "Factory from 4076.voxcdn.com" do
    before(:each) do
      VoxcastCDN.stub(:download_log).with('4076.voxcdn.com.log.1279103340-1279103400.gz') {
        File.new(Rails.root.join('spec/fixtures/logs/voxcast/4076.voxcdn.com.log.1279103340-1279103400.gz'))
      }
    end
    subject { Factory(:log_voxcast, :name => '4076.voxcdn.com.log.1279103340-1279103400.gz') }

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
      Delayed::Job.all.should have(3).job
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
        Log::Voxcast.download_and_create_new_logs
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

        it "creates 0 log" do
          expect { Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs) }.should change(Log::Voxcast, :count).by(0)
        end
        it "delays method to run in 1 min" do
          Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs)
          Delayed::Job.last.run_at.should eq 1.minute.from_now.change(sec: 0)
        end
      end

      context "with log saved 1min ago" do
        use_vcr_cassette "voxcast/download_and_create_new_logs_and_redelay 1 min ago"
        before(:each) do
          Factory(:log_voxcast, :name => Log::Voxcast.log_name("cdn.sublimevideo.net", 1.minute.ago.change(sec: 0)))
        end

        it "creates 1 log" do
          expect { Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs) }.should change(Log::Voxcast, :count).by(1)
        end
        it "delays method to run in 1 min" do
          Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs)
          Delayed::Job.last.run_at.should eq 1.minute.from_now.change(sec: 0)
        end
      end

      context "with log saved 5min ago" do
        use_vcr_cassette "voxcast/download_and_create_new_logs_and_redelay 5 min ago"
        before(:each) do
          Factory(:log_voxcast, :name => Log::Voxcast.log_name("cdn.sublimevideo.net", 5.minutes.ago.change(sec: 0)))
        end

        it "creates 5 logs" do
          expect { Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs) }.should change(Log::Voxcast, :count).by(5)
        end
        it "delays method" do
          Log::Voxcast.download_and_create_new_logs_and_redelay("cdn.sublimevideo.net", :download_and_create_new_non_ssl_logs)
          Delayed::Job.last.handler.should match "download_and_create_new_non_ssl_logs"
        end
      end

    end

    describe ".log_name" do
      specify { Log::Voxcast.log_name('cdn.sublimevideo.net', Time.utc(2011,7,7,11,37)).should eq 'cdn.sublimevideo.net.log.1310038560-1310038620.gz' }
    end

    describe ".next_log_ended_at" do
      context "with no logs saved" do
        specify { Log::Voxcast.next_log_ended_at('cdn.sublimevideo.net').should eq 1.minute.from_now.change(sec: 0) }
      end

      context "with already a log saved" do
        use_vcr_cassette "voxcast/next_log_ended_at"
        before(:each) do
          Factory(:log_voxcast, :name => "cdn.sublimevideo.net.log.#{Time.utc(2011,7,7,9,29).to_i}-#{Time.utc(2011,7,7,9,30).to_i}.gz")
          Factory(:log_voxcast, :name => "cdn.sublimevideo.net.log.#{Time.utc(2011,7,7,9,37).to_i}-#{Time.utc(2011,7,7,9,38).to_i}.gz")
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
  end

  describe "Instance Methods" do
    before(:each) do
      log_file = File.new(Rails.root.join('spec/fixtures/logs/voxcast/cdn.sublimevideo.net.log.1284549900-1284549960.gz'))
      VoxcastCDN.stub(:download_log).with('cdn.sublimevideo.net.log.1284549900-1284549960.gz') { log_file }
      @log = Factory(:log_voxcast, :name => 'cdn.sublimevideo.net.log.1284549900-1284549960.gz')
    end

    describe "parse_and_create_referrers!" do
      before(:each) do
        LogAnalyzer.should_receive(:parse)
        Referrer.should_receive(:create_or_update_from_trackers!)
        VoxcastCDN.should_not_receive(:download_log)
        subject.parse_and_create_referrers!
      end

      subject { @log }

      its(:referrers_parsed_at) { should be_present }

      it { should be_referrers_parsed }

      it "should not reparse if already done" do
        Referrer.should_not_receive(:create_or_update_from_trackers!)
        subject.parse_and_create_referrers!
      end
    end

    describe "parse_and_create_user_agents!" do
      before(:each) do
        LogAnalyzer.should_receive(:parse)
        UsrAgent.should_receive(:create_or_update_from_trackers!)
        VoxcastCDN.should_not_receive(:download_log)
        subject.parse_and_create_user_agents!
      end

      subject { @log }

      its(:user_agents_parsed_at) { should be_present }

      it { should be_user_agents_parsed }

      it "should not reparse if already done" do
        UsrAgent.should_not_receive(:create_or_update_from_trackers!)
        subject.parse_and_create_user_agents!
      end
    end
  end

end
