require 'spec_helper'

describe Site::UsageAlert do
  
  describe "Module Methods" do
    
    describe ".send_usage_alert" do
      before(:all) do
        @plan = Factory(:plan, :player_hits => 3000)
      end
      
      context "with site's usage not more than plan's limit" do
        before(:each) do
          Factory(:site_usage, { :main_player_hits => 500, :site_id => @site.id , :day => Time.now.utc.beginning_of_month })
          Factory(:site_usage, { :main_player_hits_cached => 1000, :site_id => @site.id , :day => Time.now.utc.beginning_of_month })
          Factory(:site_usage, { :extra_player_hits => 500, :site_id => @site.id , :day => Time.now.utc.beginning_of_month })
          Factory(:site_usage, { :extra_player_hits_cached => 800, :site_id => @site.id , :day => Time.now.utc.beginning_of_month })
        end
        
        context "with no last usage limit alert ever sent" do
          before(:all) { @site = Factory(:site, :plan => @plan, :activated_at => 2.months.ago, :last_usage_alert_sent_at => nil) }
          subject { @site }
          
          specify { lambda { Site::UsageAlert.send_usage_alert }.should_not change(ActionMailer::Base.deliveries, :size) }
        end
        
        context "with last usage limit alert sent before this month" do
          before(:all) { @site = Factory(:site, :plan => @plan, :activated_at => 2.months.ago, :last_usage_alert_sent_at => 1.month.ago) }
          subject { @site }
          
          specify { lambda { Site::UsageAlert.send_usage_alert }.should_not change(ActionMailer::Base.deliveries, :size) }
        end
        
        context "with last usage limit alert already sent during the month" do
          before(:all) { @site = Factory(:site, :plan => @plan, :activated_at => 2.months.ago, :last_usage_alert_sent_at => Time.now.utc.beginning_of_month) }
          subject { @site }
          
          specify { lambda { Site::UsageAlert.send_usage_alert }.should_not change(ActionMailer::Base.deliveries, :size) }
        end
      end
      
      context "with site's usage more than plan's limit" do
        before(:each) do
          Factory(:site_usage, { :main_player_hits => 1000, :site_id => @site.id , :day => Time.now.utc.beginning_of_month })
          Factory(:site_usage, { :main_player_hits_cached => 2000, :site_id => @site.id , :day => Time.now.utc.beginning_of_month })
          Factory(:site_usage, { :extra_player_hits => 1000, :site_id => @site.id , :day => Time.now.utc.beginning_of_month })
          Factory(:site_usage, { :extra_player_hits_cached => 2000, :site_id => @site.id , :day => Time.now.utc.beginning_of_month })
        end
        
        context "with no last usage limit alert ever sent" do
          before(:all) { @site = Factory(:site, :plan => @plan, :activated_at => 2.months.ago, :last_usage_alert_sent_at => nil) }
          subject { @site }
          
          specify { lambda { Site::UsageAlert.send_usage_alert }.should change(ActionMailer::Base.deliveries, :size).by(1) }
        end
        
        context "with last usage limit alert sent before this month" do
          before(:all) { @site = Factory(:site, :plan => @plan, :activated_at => 2.months.ago, :last_usage_alert_sent_at => 1.month.ago) }
          subject { @site }
          
          specify { lambda { Site::UsageAlert.send_usage_alert }.should change(ActionMailer::Base.deliveries, :size).by(1) }
        end
        
        context "with last usage limit alert already sent during the month" do
          before(:all) { @site = Factory(:site, :plan => @plan, :activated_at => 2.months.ago, :last_usage_alert_sent_at => Time.now.utc.beginning_of_month) }
          subject { @site }
          
          specify { lambda { Site::UsageAlert.send_usage_alert }.should_not change(ActionMailer::Base.deliveries, :size) }
        end
      end
      
    end
    
  end
  
end
