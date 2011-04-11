require 'spec_helper'

describe MailLetter do

  describe "Class Methods" do

    describe "#deliver_and_log" do
      before(:all) do
        @user          = Factory(:user, created_at: Time.utc(2011,1,1))
        @admin         = Factory(:admin)
        @mail_template = Factory(:mail_template)
        @attributes    = { :admin_id => @admin.id, :template_id => @mail_template.id.to_s, :criteria => "all" }
        @mail_letter   = MailLetter.new(@attributes)
      end
      subject { @mail_letter.deliver_and_log }

      it "should save all the data" do
        @user.should be_beta
        subject.admin.should    == @admin
        subject.template.should == @mail_template
        subject.criteria.should == "all"
        subject.user_ids.should == [@user.id]
        subject.snapshot.should == @mail_template.snapshotize
      end

      it "should keep a snapshot that doesn't change when the original template is modified" do
        subject
        old_snapshot = @mail_template.snapshotize
        @mail_template.reload.update_attributes(:title => "foo", :subject => "bar", :body => "John Doe")

        subject.snapshot.should_not == @mail_template.snapshotize
        subject.snapshot.should == old_snapshot
      end

      context "with multiple users to send emails to" do
        context "with the 'dev' filter" do
          before(:all) do
            @mail_letter = MailLetter.new(@attributes.merge(:criteria => 'dev'))
          end
          before(:each) { User.stub!(:where).with(:email => ["thibaud@jilion.com", "remy@jilion.com", "zeno@jilion.com", "octave@jilion.com"]).and_return([@user]) }
          subject { @mail_letter.deliver_and_log }

          it "should delay delivery of mails" do
            lambda { subject }.should change(Delayed::Job.where(:handler.matches => "%deliver%"), :count).by(1)
          end

          it "should actually send email when workers do their jobs" do
            subject
            lambda { @worker.work_off }.should change(ActionMailer::Base.deliveries, :size).by(1)
          end

          it "should send email to user with activity sites and should send appropriate template" do
            ActionMailer::Base.deliveries.clear
            subject
            @worker.work_off

            ActionMailer::Base.deliveries.last.to.should == [@user.email]
            ActionMailer::Base.deliveries.last.subject.should =~ /help us shaping the right pricing/
          end

          it "should not create a new MailLog record" do
            lambda { subject }.should_not change(MailLog, :count)
          end
        end

        context "with the 'beta_with_beta_sites' filter" do
          before(:all) do
            @user2 = Factory(:user, created_at: Time.utc(2011,1,1))
            @user3 = Factory(:user)
            @user.should be_beta
            @user2.should be_beta
            @user3.should_not be_beta
            
            Plan.delete_all
            beta_plan = Factory(:plan, name: "beta", player_hits: 0, cycle: "none")
            comet = Factory(:plan, name: "comet",  player_hits: 3_000)
            
            Timecop.travel(15.days.ago) do
              @site1 = Factory(:beta_site, pending_plan_id: beta_plan.id, user: @user) # will receive an email
              @site1.should be_in_beta_plan
              Factory(:beta_site, pending_plan_id: beta_plan.id, user: @user, state: 'archived')
              
              @site2 = Factory(:site, pending_plan_id: comet.id, user: @user2) # will not receive an email (not a beta plan)
              @site2.should_not be_in_beta_plan
              
              @site3 = Factory(:beta_site, pending_plan_id: beta_plan.id, user: @user3) # will not receive an email (not a beta user)
              @site3.should be_in_beta_plan
            end
          end
          subject { MailLetter.new(@attributes.merge(:criteria => 'beta_with_beta_sites')).deliver_and_log }

          it "should delay delivery of mails" do
            lambda { subject }.should change(Delayed::Job.where(:handler.matches => "%deliver%"), :count).by(1)
          end

          it "should actually send email when workers do their jobs" do
            subject
            lambda { @worker.work_off }.should change(ActionMailer::Base.deliveries, :size).by(1)
          end

          it "should send email to user with invalid sites and should send appropriate template" do
            ActionMailer::Base.deliveries.clear
            subject
            @worker.work_off

            ActionMailer::Base.deliveries.last.to.should == [@user.email]
            ActionMailer::Base.deliveries.last.subject.should =~ /help us shaping the right pricing/
          end

          it "should create a new MailLog record" do
            lambda { subject }.should change(MailLog, :count).by(1)
          end
        end

        context "with the 'beta_with_recommended_plan' filter" do
          before(:all) do
            Plan.delete_all
            beta_plan = Factory(:plan, name: "beta", player_hits: 0, cycle: "none")
            Factory(:plan, name: "comet",  player_hits: 3_000)
            Factory(:plan, name: "planet", player_hits: 50_000)
            Factory(:plan, name: "star",   player_hits: 200_000)
            Factory(:plan, name: "galaxy", player_hits: 1_000_000)
            Timecop.travel(15.days.ago) do
              @site1 = Factory(:beta_site, pending_plan_id: beta_plan.id, user: @user)
              @site2 = Factory(:beta_site, pending_plan_id: beta_plan.id, user: @user)
              @site3 = Factory(:beta_site, pending_plan_id: beta_plan.id, user: @user, state: 'archived')
              Factory(:beta_site, pending_plan_id: beta_plan.id, user: Factory(:user))
            end
          end
          before(:each) do
            @site1.unmemoize_all
            @site2.unmemoize_all
            @site3.unmemoize_all
            Factory(:site_usage, site_id: @site1.id, day: 1.day.ago,  main_player_hits: 1000)
            Factory(:site_usage, site_id: @site1.id, day: 2.days.ago, main_player_hits: 1000)
            Factory(:site_usage, site_id: @site1.id, day: 3.days.ago, main_player_hits: 1000)
            Factory(:site_usage, site_id: @site1.id, day: 4.days.ago, main_player_hits: 1000)
            Factory(:site_usage, site_id: @site1.id, day: 5.days.ago, main_player_hits: 1000)
            Factory(:site_usage, site_id: @site2.id, day: 1.day.ago,  main_player_hits: 1000)
            Factory(:site_usage, site_id: @site2.id, day: 2.days.ago, main_player_hits: 1000)
            Factory(:site_usage, site_id: @site2.id, day: 3.days.ago, main_player_hits: 1000)
            Factory(:site_usage, site_id: @site2.id, day: 4.days.ago, main_player_hits: 1000)
            Factory(:site_usage, site_id: @site2.id, day: 5.days.ago, main_player_hits: 1000)
            Factory(:site_usage, site_id: @site3.id, day: 1.day.ago,  main_player_hits: 1000)
            Factory(:site_usage, site_id: @site3.id, day: 2.days.ago, main_player_hits: 1000)
            Factory(:site_usage, site_id: @site3.id, day: 3.days.ago, main_player_hits: 1000)
            Factory(:site_usage, site_id: @site3.id, day: 4.days.ago, main_player_hits: 1000)
            Factory(:site_usage, site_id: @site3.id, day: 5.days.ago, main_player_hits: 1000)
          end
          subject { MailLetter.new(@attributes.merge(:criteria => 'beta_with_recommended_plan')).deliver_and_log }

          it "should delay delivery of mails" do
            lambda { subject }.should change(Delayed::Job.where(:handler.matches => "%deliver%"), :count).by(1)
          end

          it "should actually send email when workers do their jobs" do
            subject
            lambda { @worker.work_off }.should change(ActionMailer::Base.deliveries, :size).by(1)
          end

          it "should send email to user with invalid sites and should send appropriate template" do
            ActionMailer::Base.deliveries.clear
            subject
            @worker.work_off

            ActionMailer::Base.deliveries.last.to.should == [@user.email]
            ActionMailer::Base.deliveries.last.subject.should =~ /help us shaping the right pricing/
          end

          it "should create a new MailLog record" do
            lambda { subject }.should change(MailLog, :count).by(1)
          end
        end
      end

    end

  end

end
