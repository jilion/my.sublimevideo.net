require 'spec_helper'

describe SiteModules::UsageMonitoring do

  describe ".monitor_sites_usages" do
    let(:plan) { create(:plan, video_views: 30 * 100) }

    it "should do nothing" do
      Timecop.travel(Time.utc(2011,1,1)) { @site = create(:site, plan_id: plan.id) }

      expect { Site.monitor_sites_usages }.to_not change(Delayed::Job, :count)
      @site.reload
      @site.overusage_notification_sent_at.should be_nil
      @site.first_plan_upgrade_required_alert_sent_at.should be_nil
    end

    pending "with required upgrade site" do
      before do
        Timecop.travel(Time.utc(2011,1,1)) { @site = create(:site, plan_id: plan.id) }
        (1..20).each do |day|
          create(:site_day_stat, t: @site.token, d: Time.utc(2011,1,day), vv: { m: 200 })
        end
      end

      it "should required upgrade and send alert" do
        @site.first_plan_upgrade_required_alert_sent_at.should be_nil
        expect { Timecop.travel(Time.utc(2011,1,22)) { Site.monitor_sites_usages } }.to change(Delayed::Job.where{ handler =~ "%Class%plan_overused%" }, :count).by(1)
        @site.reload.first_plan_upgrade_required_alert_sent_at.should be_present
      end

      it "should not send alert" do
        @site.touch(:first_plan_upgrade_required_alert_sent_at)
        first_plan_upgrade_required_alert_sent_at = @site.first_plan_upgrade_required_alert_sent_at

        UsageMonitoringMailer.should_not_receive(:delay)
        Timecop.travel(Time.utc(2011,1,22)) { Site.monitor_sites_usages }
        @site.reload.first_plan_upgrade_required_alert_sent_at.should be_within(5).of(first_plan_upgrade_required_alert_sent_at) # no change
      end
    end

    context "with reached player hits site" do
      before do
        Timecop.travel(Time.utc(2011,1,1)) { @site = create(:site, plan_id: plan.id) }
        create(:site_day_stat, t: @site.token, d: Time.utc(2011,1,1), vv: { m: 3001 })
      end

      it "should send player hits reached notification" do
        @site.overusage_notification_sent_at.should be_nil
        expect { Timecop.travel(Time.utc(2011,1,22)) { Site.monitor_sites_usages } }.to change(Delayed::Job.where{ handler =~ "%Class%plan_overused%" }, :count).by(1)
        @site.reload.overusage_notification_sent_at.should be_present
        @site.first_plan_upgrade_required_alert_sent_at.should be_nil
      end

      it "should send player hits reached notification if not sent during the site cycle" do
        Timecop.travel(Time.utc(2010,12,20)) { @site.touch(:overusage_notification_sent_at) }
        expect { Timecop.travel(Time.utc(2011,1,22)) { Site.monitor_sites_usages } }.to change(Delayed::Job.where{ handler =~ "%Class%plan_overused%" }, :count).by(1)
        @site.reload
        @site.overusage_notification_sent_at.should > Time.utc(2011,1,22)
        @site.first_plan_upgrade_required_alert_sent_at.should be_nil
      end

      it "should not send player hits reached notification if already sent during the site cycle" do
        Timecop.travel(Time.utc(2011,1,20)) { @site.touch(:overusage_notification_sent_at) }
        expect { Timecop.travel(Time.utc(2011,1,22)) { Site.monitor_sites_usages } }.to_not change(Delayed::Job, :count)
        @site.reload
        @site.overusage_notification_sent_at.should_not be_nil
        @site.first_plan_upgrade_required_alert_sent_at.should be_nil
      end
    end
  end

end
