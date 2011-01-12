require 'spec_helper'

describe Site::UsageAlert do

  describe "Module Methods" do

    describe ".send_usage_alerts" do
      before(:all) do
        @plan1 = Factory(:plan, :player_hits => 3000, :price => 5, :overage_price => 1)
        @plan2 = Factory(:plan, :player_hits => 9000, :price => 10)
      end

      context "with site's usage not more than plan's limit" do
        before(:each) do
          Factory(:site_usage, { :main_player_hits => 1500, :site_id => @site.id , :day => Time.now.utc.beginning_of_month })
          Factory(:site_usage, { :extra_player_hits => 1300, :site_id => @site.id , :day => Time.now.utc.beginning_of_month })
        end

        context "with no last usage limit alert ever sent" do
          before(:all) { @site = Factory(:site, :plan => @plan1, :activated_at => 2.months.ago, :plan_player_hits_reached_alert_sent_at => nil) }
          subject { @site }

          specify { lambda { Site::UsageAlert.send_usage_alerts }.should_not change(ActionMailer::Base.deliveries, :size) }
        end

        context "with last usage limit alert sent before this month" do
          before(:all) { @site = Factory(:site, :plan => @plan1, :activated_at => 2.months.ago, :plan_player_hits_reached_alert_sent_at => 1.month.ago) }
          subject { @site }

          specify { lambda { Site::UsageAlert.send_usage_alerts }.should_not change(ActionMailer::Base.deliveries, :size) }
        end

        context "with last usage limit alert already sent during the month" do
          before(:all) { @site = Factory(:site, :plan => @plan1, :activated_at => 2.months.ago, :plan_player_hits_reached_alert_sent_at => Time.now.utc.beginning_of_month) }
          subject { @site }

          specify { lambda { Site::UsageAlert.send_usage_alerts }.should_not change(ActionMailer::Base.deliveries, :size) }
        end
      end

      context "with site's usage more than plan's limit but less than next plan price" do
        before(:each) do
          Factory(:site_usage, { :main_player_hits => 1600, :site_id => @site.id , :day => Time.now.utc.beginning_of_month })
          Factory(:site_usage, { :extra_player_hits => 1600, :site_id => @site.id , :day => Time.now.utc.beginning_of_month })
        end

        context "with no last usage limit alert ever sent" do
          before(:all) { @site = Factory(:site, :plan => @plan1, :activated_at => 2.months.ago, :plan_player_hits_reached_alert_sent_at => nil) }
          subject { @site }

          specify { lambda { Site::UsageAlert.send_usage_alerts }.should change(ActionMailer::Base.deliveries, :size).by(1) }
        end

        context "with last usage limit alert sent before this month" do
          before(:all) do
            @site = Factory(:site, :plan => @plan1, :activated_at => 2.months.ago)
            @site.update_attribute(:plan_player_hits_reached_alert_sent_at, 1.month.ago)
          end
          subject { @site }

          specify { subject.plan_player_hits_reached_alert_sent_at.should be_within(5).of(1.month.ago) }
          specify { lambda { Site::UsageAlert.send_usage_alerts }.should change(ActionMailer::Base.deliveries, :size).by(1) }
        end

        context "with last usage limit alert already sent during the month" do
          before(:all) do
            @site = Factory(:site, :plan => @plan1, :activated_at => 2.months.ago)
            @site.update_attribute(:plan_player_hits_reached_alert_sent_at, Time.now.utc.beginning_of_month)
          end
          subject { @site }

          specify { subject.plan_player_hits_reached_alert_sent_at.should be_within(5).of(Time.now.utc.beginning_of_month) }
          specify { lambda { Site::UsageAlert.send_usage_alerts }.should_not change(ActionMailer::Base.deliveries, :size) }
        end
      end

      context "with site's usage more than plan's limit and more than next plan price" do
        before(:each) do
          Factory(:site_usage, { :main_player_hits => 30000, :site_id => @site.id , :day => Time.now.utc.beginning_of_month })
          Factory(:site_usage, { :extra_player_hits => 30000, :site_id => @site.id , :day => Time.now.utc.beginning_of_month })
        end

        context "with no plan_player_hits_reached alert nor next_plan_recommended alert ever sent" do
          before(:all) { @site = Factory(:site, :plan => @plan1, :activated_at => 2.months.ago, :plan_player_hits_reached_alert_sent_at => nil, :next_plan_recommended_alert_sent_at => nil) }
          subject { @site }

          specify { lambda { Site::UsageAlert.send_usage_alerts }.should change(ActionMailer::Base.deliveries, :size).by(2) }
        end

        context "with plan_player_hits_reached alert sent before this month and next_plan_recommended alert never sent" do
          before(:all) do
            @site = Factory(:site, :plan => @plan1, :activated_at => 2.months.ago, :next_plan_recommended_alert_sent_at => nil)
            @site.update_attribute(:plan_player_hits_reached_alert_sent_at, 1.month.ago)
          end
          subject { @site }

          specify { subject.plan_player_hits_reached_alert_sent_at.should be_within(5).of(1.month.ago) }
          specify { lambda { Site::UsageAlert.send_usage_alerts }.should change(ActionMailer::Base.deliveries, :size).by(2) }
        end

        context "with plan_player_hits_reached alert and next_plan_recommended alert sent before this month" do
          before(:all) do
            @site = Factory(:site, :plan => @plan1, :activated_at => 2.months.ago)
            @site.update_attribute(:plan_player_hits_reached_alert_sent_at, 1.month.ago)
            @site.update_attribute(:next_plan_recommended_alert_sent_at, 1.month.ago)
          end
          subject { @site }

          specify { subject.plan_player_hits_reached_alert_sent_at.should be_within(5).of(1.month.ago) }
          specify { subject.next_plan_recommended_alert_sent_at.should be_within(5).of(1.month.ago) }
          specify { lambda { Site::UsageAlert.send_usage_alerts }.should change(ActionMailer::Base.deliveries, :size).by(2) }
        end

        context "with plan_player_hits_reached alert already sent during the month and next_plan_recommended alert not sent" do
          before(:all) do
            @site = Factory(:site, :plan => @plan1, :activated_at => 2.months.ago, :next_plan_recommended_alert_sent_at => nil)
            @site.update_attribute(:plan_player_hits_reached_alert_sent_at, Time.now.utc.beginning_of_month)
          end
          subject { @site }

          specify { subject.plan_player_hits_reached_alert_sent_at.should be_within(5).of(Time.now.utc.beginning_of_month) }
          specify { lambda { Site::UsageAlert.send_usage_alerts }.should change(ActionMailer::Base.deliveries, :size).by(1) }
        end

        context "with plan_player_hits_reached alert already sent during the month and next_plan_recommended alert not sent and no next_plan" do
          before(:all) do
            @site = Factory(:site, :plan => @plan2, :activated_at => 2.months.ago, :next_plan_recommended_alert_sent_at => nil)
            @site.update_attribute(:plan_player_hits_reached_alert_sent_at, Time.now.utc.beginning_of_month)
          end
          subject { @site }

          specify { subject.plan_player_hits_reached_alert_sent_at.should be_within(5).of(Time.now.utc.beginning_of_month) }
          specify { lambda { Site::UsageAlert.send_usage_alerts }.should_not change(ActionMailer::Base.deliveries, :size) }
        end

        context "with plan_player_hits_reached alert and next_plan_recommended alert already sent during the month" do
          before(:all) do
            @site = Factory(:site, :plan => @plan1, :activated_at => 2.months.ago)
            @site.update_attribute(:plan_player_hits_reached_alert_sent_at, Time.now.utc.beginning_of_month)
            @site.update_attribute(:next_plan_recommended_alert_sent_at, Time.now.utc.beginning_of_month)
          end
          subject { @site }

          specify { subject.plan_player_hits_reached_alert_sent_at.should be_within(5).of(Time.now.utc.beginning_of_month) }
          specify { subject.next_plan_recommended_alert_sent_at.should be_within(5).of(Time.now.utc.beginning_of_month) }
          specify { lambda { Site::UsageAlert.send_usage_alerts }.should_not change(ActionMailer::Base.deliveries, :size) }
        end
      end
    end

  end

end
