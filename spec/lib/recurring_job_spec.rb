require 'spec_helper'

describe RecurringJob do

  describe ".delay_download_or_fetch_and_create_new_logs" do
    use_vcr_cassette "log/delay_download_or_fetch_and_create_new_logs"

    it "should call Log::Voxcast download_and_create_new_logs" do
      Log::Voxcast.should_receive(:download_and_create_new_logs)
      described_class.delay_download_or_fetch_and_create_new_logs
    end

    it "should call Log::Amazon::S3::Player delay_fetch_and_create_new_logs" do
      Log::Amazon::S3::Player.should_receive(:delay_fetch_and_create_new_logs)
      described_class.delay_download_or_fetch_and_create_new_logs
    end

    it "should call Log::Amazon::S3::Loaders delay_fetch_and_create_new_logs" do
      Log::Amazon::S3::Loaders.should_receive(:delay_fetch_and_create_new_logs)
      described_class.delay_download_or_fetch_and_create_new_logs
    end

    it "should call Log::Amazon::S3::Licenses delay_fetch_and_create_new_logs" do
      Log::Amazon::S3::Licenses.should_receive(:delay_fetch_and_create_new_logs)
      described_class.delay_download_or_fetch_and_create_new_logs
    end
  end

  %w[invoices sites users tweets stats].each do |type|
    describe ".delay_#{type}_processing" do
      it "delays #{type}_processing only once at max" do
        -> { 3.times { described_class.send("delay_#{type}_processing") } }.should delay("%RecurringJob%#{type}_processing%")
      end
    end

    describe ".#{type}_processing" do
      it "delays #{type}_processing" do
        -> { described_class.send("#{type}_processing") }.should delay("%RecurringJob%#{type}_processing%")
      end
    end
  end

  describe ".invoices_processing" do
    it "delays 2 methods" do
      -> { described_class.invoices_processing }.should delay(%w[
        %Service::Invoice%create_invoices_for_month%
        %Transaction%charge_invoices%])
    end
  end

  describe ".sites_processing" do
    it "delays 3 methods" do
      -> { described_class.sites_processing }.should delay(%w[
        %Service::Usage%update_last_30_days_counters_for_not_archived_sites%
        %Service::Usage%set_first_billable_plays_at_for_not_archived_sites%
        %Service::Trial%activate_billable_items_out_of_trial!%])
    end
  end

  describe ".users_processing" do
    it "calls 1 method" do
      -> { described_class.users_processing }.should delay(%w[
        %User%send_credit_card_expiration%
        %User%send_inactive_account_email%])
    end
  end

  describe ".tweets_processing" do
    it "calls 1 method" do
      -> { described_class.tweets_processing }.should delay('%Tweet%save_new_tweets_and_sync_favorite_tweets%')
    end
  end

  describe ".stats_processing" do
    it "calls 6 methods" do
      -> { described_class.stats_processing }.should delay(%w[Users Sites Sales SiteStats SiteUsages Tweets].map do |stats_klass|
        "%Stats::#{stats_klass}Stat%create_stats%"
      end)
    end
  end

  describe ".launch_all" do
    use_vcr_cassette "recurring_job/launch_all"

    described_class::NAMES.each do |name|
      it "launches #{name} recurring job" do
        Delayed::Job.already_delayed?(name).should be_false
        described_class.launch_all
        Delayed::Job.already_delayed?(name).should be_true
      end
    end
  end

  describe ".supervise" do
    use_vcr_cassette "recurring_job/supervise"

    it "doesn't notify if all recurring jobs are delayed" do
      described_class.launch_all
      Notify.should_not_receive(:send)
      described_class.supervise(50, 1)
    end
  end

end
