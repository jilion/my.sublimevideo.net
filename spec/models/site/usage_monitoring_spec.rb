require 'spec_helper'

describe Site::UsageMonitoring do

  describe ".delay_monitor_sites_usages" do
    it "should delay monitor_sites_usage if not already delayed" do
      expect { Site::UsageMonitoring.delay_monitor_sites_usages }.should change(Delayed::Job.where(:handler.matches => '%Site::UsageMonitoring%monitor_sites_usage%'), :count).by(1)
    end

    it "should not delay monitor_sites_usage if already delayed" do
      Site::UsageMonitoring.delay_monitor_sites_usages
      expect { Site::UsageMonitoring.delay_monitor_sites_usages }.should change(Delayed::Job.where(:handler.matches => '%Site::UsageMonitoring%monitor_sites_usage%'), :count).by(0)
    end
  end

  describe ".monitor_sites_usages" do
    before(:all) { @plan = FactoryGirl.create(:plan, player_hits: 30 * 100) }

    it "should do nothing" do
      Timecop.travel(Time.utc(2011,1,1)) { @site = FactoryGirl.create(:site, plan_id: @plan.id) }

      UsageMonitoringMailer.should_not_receive(:plan_player_hits_reached)
      UsageMonitoringMailer.should_not_receive(:plan_upgrade_required)
      Site::UsageMonitoring.monitor_sites_usages
      @site.reload
      @site.plan_player_hits_reached_notification_sent_at.should be_nil
      @site.first_plan_upgrade_required_alert_sent_at.should be_nil
    end

    pending "with required upgrade site" do
      before(:each) do
        Timecop.travel(Time.utc(2011,1,1)) { @site = FactoryGirl.create(:site, plan_id: @plan.id) }
        (1..20).each do |day|
          FactoryGirl.create(:site_usage, site_id: @site.id, day: Time.utc(2011,1,day), main_player_hits: 200)
        end
      end

      it "should required upgrade and send alert" do
        @site.first_plan_upgrade_required_alert_sent_at.should be_nil
        UsageMonitoringMailer.should_receive(:plan_upgrade_required).with(@site).and_return ( mock(:deliver! => true) )
        Timecop.travel(Time.utc(2011,1,22)) { Site::UsageMonitoring.monitor_sites_usages }
        @site.reload.first_plan_upgrade_required_alert_sent_at.should be_present
      end

      it "should not send alert" do
        @site.touch(:first_plan_upgrade_required_alert_sent_at)
        first_plan_upgrade_required_alert_sent_at = @site.first_plan_upgrade_required_alert_sent_at

        UsageMonitoringMailer.should_not_receive(:plan_upgrade_required).with(@site)
        Timecop.travel(Time.utc(2011,1,22)) { Site::UsageMonitoring.monitor_sites_usages }
        @site.reload.first_plan_upgrade_required_alert_sent_at.should be_within(5).of(first_plan_upgrade_required_alert_sent_at) # no change
      end
    end

    context "with reached player hits site" do
      before(:each) do
        Timecop.travel(Time.utc(2011,1,1)) { @site = FactoryGirl.create(:site_not_in_trial, plan_id: @plan.id) }
        FactoryGirl.create(:site_usage, site_id: @site.id, day: Time.utc(2011,1,1), main_player_hits: 3001)
      end

      it "should send player hits reached notification" do
        @site.plan_player_hits_reached_notification_sent_at.should be_nil
        UsageMonitoringMailer.should_receive(:plan_player_hits_reached).with(@site).and_return ( mock(:deliver! => true) )
        Timecop.travel(Time.utc(2011,1,22)) { Site::UsageMonitoring.monitor_sites_usages }
        @site.reload.plan_player_hits_reached_notification_sent_at.should be_present
        @site.first_plan_upgrade_required_alert_sent_at.should be_nil
      end

      it "should send player hits reached notification if not sent during the site cycle" do
        Timecop.travel(Time.utc(2010,12,20)) { @site.touch(:plan_player_hits_reached_notification_sent_at) }

        UsageMonitoringMailer.should_receive(:plan_player_hits_reached).with(@site).and_return ( mock(:deliver! => true) )
        UsageMonitoringMailer.should_not_receive(:plan_upgrade_required)
        Timecop.travel(Time.utc(2011,1,22)) { Site::UsageMonitoring.monitor_sites_usages }
        @site.reload
        @site.plan_player_hits_reached_notification_sent_at.should > Time.utc(2011,1,22)
        @site.first_plan_upgrade_required_alert_sent_at.should be_nil
      end

      it "should not send player hits reached notification if already sent during the site cycle" do
        Timecop.travel(Time.utc(2011,1,20)) { @site.touch(:plan_player_hits_reached_notification_sent_at) }

        UsageMonitoringMailer.should_not_receive(:plan_player_hits_reached)
        UsageMonitoringMailer.should_not_receive(:plan_upgrade_required)
        Timecop.travel(Time.utc(2011,1,22)) { Site::UsageMonitoring.monitor_sites_usages }
        @site.reload
        @site.plan_player_hits_reached_notification_sent_at.should_not be_nil
        @site.first_plan_upgrade_required_alert_sent_at.should be_nil
      end
    end
  end

end
