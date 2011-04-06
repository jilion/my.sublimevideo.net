require 'spec_helper'

describe MailLetter do

  describe "Class Methods" do

    describe "#deliver_and_log" do
      before(:all) do
        @user          = Factory(:user, created_at: Time.utc(2011,1,1))
        @site          = Factory(:site, user: @user).tap { |site| site.update_attribute(:hostname, 'localhost') }
        @admin         = Factory(:admin)
        @mail_template = Factory(:mail_template)
        @attributes    = { :admin_id => @admin.id, :template_id => @mail_template.id.to_s, :criteria => "with_invalid_site" }
        @mail_letter   = MailLetter.new(@attributes)
      end
      subject { @mail_letter.deliver_and_log }

      it "should save all the data" do
        @user.should be_beta
        @site.should_not be_valid
        subject.admin.should    == @admin
        subject.template.should == @mail_template
        subject.criteria.should == "with_invalid_site"
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

        context "with the 'beta_with_recommended_plan' filter", focus: true do
          before(:all) do
            Plan.delete_all
            Factory(:plan, name: "comet",  player_hits: 3_000)
            Factory(:plan, name: "planet", player_hits: 50_000)
            Factory(:plan, name: "star",   player_hits: 200_000)
            Factory(:plan, name: "galaxy", player_hits: 1_000_000)
            Timecop.travel(15.days.ago) { @site = Factory(:beta_site, user: @user) }
          end
          before(:each) do
            @site.unmemoize_all
            Factory(:site_usage, site_id: @site.id, day: 1.day.ago,  main_player_hits: 1000)
            Factory(:site_usage, site_id: @site.id, day: 2.days.ago, main_player_hits: 1000)
            Factory(:site_usage, site_id: @site.id, day: 3.days.ago, main_player_hits: 1000)
            Factory(:site_usage, site_id: @site.id, day: 4.days.ago, main_player_hits: 1000)
            Factory(:site_usage, site_id: @site.id, day: 5.days.ago, main_player_hits: 1000)
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
