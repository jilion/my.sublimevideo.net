require 'spec_helper'

describe RecurringJob do

  describe ".delay_download_or_fetch_and_create_new_logs" do
    use_vcr_cassette "log/delay_download_or_fetch_and_create_new_logs"

    it "should call Log::Voxcast download_and_create_new_logs" do
      Log::Voxcast.should_receive(:download_and_create_new_logs)
      Log.delay_download_or_fetch_and_create_new_logs
    end

    it "should call Log::Amazon::S3::Player delay_fetch_and_create_new_logs" do
      Log::Amazon::S3::Player.should_receive(:delay_fetch_and_create_new_logs)
      Log.delay_download_or_fetch_and_create_new_logs
    end

    it "should call Log::Amazon::S3::Loaders delay_fetch_and_create_new_logs" do
      Log::Amazon::S3::Loaders.should_receive(:delay_fetch_and_create_new_logs)
      Log.delay_download_or_fetch_and_create_new_logs
    end

    it "should call Log::Amazon::S3::Licenses delay_fetch_and_create_new_logs" do
      Log::Amazon::S3::Licenses.should_receive(:delay_fetch_and_create_new_logs)
      Log.delay_download_or_fetch_and_create_new_logs
    end
  end

  describe ".delay_invoices_processing" do
    it "delays invoices_processing if not already delayed" do
      expect { RecurringJob.delay_invoices_processing }.to change(Delayed::Job.where(:handler.matches => '%RecurringJob%invoices_processing%'), :count).by(1)
    end

    it "doesn't delay invoices_processing if already delayed" do
      RecurringJob.delay_invoices_processing
      expect { RecurringJob.delay_invoices_processing }.to_not change(Delayed::Job.where(:handler.matches => '%RecurringJob%invoices_processing%'), :count)
    end
  end

  describe ".invoices_processing" do
    it "calls 4 methods" do
      Invoice.should_receive(:update_pending_dates_for_first_not_paid_invoices)
      Site.should_receive(:activate_or_downgrade_sites_leaving_trial)
      Site.should_receive(:renew_active_sites)
      Transaction.should_receive(:charge_invoices)

      RecurringJob.invoices_processing
    end

    it "calls delay_invoices_processing" do
      RecurringJob.should_receive(:delay_invoices_processing)

      RecurringJob.invoices_processing
    end
  end

  describe ".sites_processing" do
    it "calls 3 methods" do
      Site.should_receive(:send_trial_will_expire)
      Site.should_receive(:monitor_sites_usages)
      Site.should_receive(:update_last_30_days_counters_for_not_archived_sites)

      RecurringJob.sites_processing
    end

    it "calls delay_sites_processing" do
      RecurringJob.should_receive(:delay_sites_processing)

      RecurringJob.sites_processing
    end
  end

  describe ".users_processing" do
    it "calls 1 method" do
      User.should_receive(:send_credit_card_expiration)

      RecurringJob.users_processing
    end

    it "calls delay_users_processing" do
      RecurringJob.should_receive(:delay_users_processing)

      RecurringJob.users_processing
    end
  end

  describe ".stats_processing" do
    it "calls 5 methods" do
      Stats::UsersStat.should_receive(:create_users_stats)
      Stats::SitesStat.should_receive(:create_sites_stats)
      Stats::SiteStatsStat.should_receive(:create_site_stats_stats)
      Stats::SiteUsagesStat.should_receive(:create_site_usages_stats)
      Stats::TweetsStat.should_receive(:create_tweets_stats)

      RecurringJob.stats_processing
    end

    it "calls delay_stats_processing" do
      RecurringJob.should_receive(:delay_stats_processing)

      RecurringJob.stats_processing
    end
  end

  describe ".launch_all" do
    use_vcr_cassette "recurring_job/launch_all"

    RecurringJob::NAMES.each do |name|
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
      subject.supervise
    end

    it "notifies if all recurring jobs aren't delayed" do
      subject.launch_all
      Delayed::Job.last.delete
      Notify.should_receive(:send)
      subject.supervise
    end
  end

end
