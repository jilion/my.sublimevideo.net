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

  describe ".delay_invoices_processing" do
    it "delays invoices_processing if not already delayed" do
      expect { described_class.delay_invoices_processing }.to change(Delayed::Job.where { handler =~ '%RecurringJob%invoices_processing%' }, :count).by(1)
    end

    it "doesn't delay invoices_processing if already delayed" do
      described_class.delay_invoices_processing
      expect { described_class.delay_invoices_processing }.to_not change(Delayed::Job.where{ handler =~ '%RecurringJob%invoices_processing%' }, :count)
    end
  end

  describe ".invoices_processing" do
    it "delays 4 methods" do
      described_class.invoices_processing

      Delayed::Job.where { handler =~ '%Invoice%update_pending_dates_for_first_not_paid_invoices%' }.should have(1).item
      Delayed::Job.where { handler =~ '%Site%downgrade_sites_leaving_trial%' }.should have(1).item
      Delayed::Job.where { handler =~ '%Site%renew_active_sites%' }.should have(1).item
      Delayed::Job.where { handler =~ '%Transaction%charge_invoices%' }.should have(1).item
    end

    it "calls delay_invoices_processing" do
      described_class.should_receive(:delay_invoices_processing)

      described_class.invoices_processing
    end
  end

  describe ".sites_processing" do
    it "calls 3 methods" do
      described_class.sites_processing

      Delayed::Job.where { handler =~ '%Site%send_trial_will_expire_email%' }.should have(1).item
      Delayed::Job.where { handler =~ '%Site%send_yearly_plan_will_be_renewed_email%' }.should have(1).item
      Delayed::Job.where { handler =~ '%Site%monitor_sites_usages%' }.should have(1).item
      Delayed::Job.where { handler =~ '%Site%update_last_30_days_counters_for_not_archived_sites%' }.should have(1).item
    end

    it "calls delay_sites_processing" do
      described_class.should_receive(:delay_sites_processing)

      described_class.sites_processing
    end
  end

  describe ".users_processing" do
    it "calls 1 method" do
      described_class.users_processing

      Delayed::Job.where { handler =~ '%User%send_credit_card_expiration%' }.should have(1).item
      Delayed::Job.where { handler =~ '%User%send_inactive_account_email%' }.should have(1).item
    end

    it "calls delay_users_processing" do
      described_class.should_receive(:delay_users_processing)

      described_class.users_processing
    end
  end

  describe ".tweets_processing" do
    it "calls 1 method" do
      described_class.tweets_processing

      Delayed::Job.where { handler =~ '%Tweet%save_new_tweets_and_sync_favorite_tweets%' }.should have(1).item
    end

    it "calls delay_tweets_processing" do
      described_class.should_receive(:delay_tweets_processing)

      described_class.tweets_processing
    end
  end

  describe ".stats_processing" do
    it "calls 5 methods" do
      described_class.stats_processing

      %w[Users Sites Sales SiteStats SiteUsages Tweets].each do |stats_klass|
        Delayed::Job.where { handler =~ "%Stats::#{stats_klass}Stat%create_stats%" }.should have(1).item
      end
    end

    it "calls delay_stats_processing" do
      described_class.should_receive(:delay_stats_processing)

      described_class.stats_processing
    end
  end

  describe ".launch_all" do
    use_vcr_cassette "recurring_job/launch_all"

    described_class::NAMES.each do |name|
      it "launches #{name} recurring job" do
        Delayed::Job.already_delayed?(name).should be_false
        subject.launch_all
        Delayed::Job.already_delayed?(name).should be_true
      end
    end
  end

  describe ".supervise" do
    use_vcr_cassette "recurring_job/supervise"

    it "doesn't notify if all recurring jobs are delayed" do
      subject.launch_all
      Notify.should_not_receive(:send)
      subject.supervise(50, 1)
    end

    # it "notifies if all recurring jobs aren't delayed" do
    #   subject.launch_all
    #   Delayed::Job.last.delete
    #   Notify.should_receive(:send)
    #   subject.supervise(50, 1, 1)
    # end
  end

end
