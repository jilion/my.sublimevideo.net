require 'spec_helper'

describe MailLetter do

  describe "Class Methods" do

    describe "#deliver_and_log" do
      before(:all) do
        @user          = Factory.create(:user, created_at: Time.utc(2011,1,1))
        @admin         = Factory.create(:admin)
        @mail_template = Factory.create(:mail_template)
        @attributes    = { admin_id: @admin.id, template_id: @mail_template.id.to_s, criteria: "all" }
        @mail_letter   = MailLetter.new(@attributes)
      end
      subject { @mail_letter.deliver_and_log }

      it "should save all the data" do
        @user.should be_beta
        subject.admin.should    eq @admin
        subject.template.should eq @mail_template
        subject.criteria.should eq "all"
        subject.user_ids.should eq [@user.id]
        subject.snapshot.should eq @mail_template.snapshotize
      end

      it "should keep a snapshot that doesn't change when the original template is modified" do
        subject
        old_snapshot = @mail_template.snapshotize
        @mail_template.reload.update_attributes(title: "foo", subject: "bar", body: "John Doe")

        subject.snapshot.should_not eq @mail_template.snapshotize
        subject.snapshot.should eq old_snapshot
      end

      context "with multiple users to send emails to" do
        context "with the 'dev' filter" do
          before(:all) do
            @mail_letter = MailLetter.new(@attributes.merge(criteria: 'dev'))
          end
          before(:each) { User.stub!(:where).with(email: ["thibaud@jilion.com", "remy@jilion.com", "zeno@jilion.com", "octave@jilion.com"]).and_return([@user]) }
          subject { @mail_letter.deliver_and_log }

          it "delays delivery of mails" do
            expect { subject }.to change(Delayed::Job.where(:handler.matches => "%deliver%"), :count).by(1)
          end

          it "actually sends email when workers do their jobs" do
            subject
            lambda { @worker.work_off }.should change(ActionMailer::Base.deliveries, :size).by(1)
          end

          it "sends email to user with activity sites and should send appropriate template" do
            ActionMailer::Base.deliveries.clear
            subject
            @worker.work_off

            ActionMailer::Base.deliveries.last.to.should eq [@user.email]
            ActionMailer::Base.deliveries.last.subject.should =~ /help us shaping the right pricing/
          end

          it "doesn't create a new MailLog record" do
            expect { subject }.to_not change(MailLog, :count)
          end
        end

        describe "the 'active_and_billable' and 'active_and_not_billable' filters" do
          before(:all) do
            @archived_user = Factory.create(:user, state: 'archived')
            @billable_user = Factory.create(:user)
            Factory.create(:site, user: @billable_user)
          end

          context "with the 'active_and_billable' filter" do
            subject { MailLetter.new(@attributes.merge(criteria: 'active_and_billable')).deliver_and_log }

            it "delays delivery of mails" do
              expect { subject }.to change(Delayed::Job.where(:handler.matches => "%deliver%"), :count).by(1)
            end

            it "actually sends email when workers do their jobs" do
              subject
              expect { @worker.work_off }.to change(ActionMailer::Base.deliveries, :size).by(1)
            end

            it "sends email to active and billable users and should send appropriate template" do
              ActionMailer::Base.deliveries.clear
              subject
              @worker.work_off

              ActionMailer::Base.deliveries.last.to.should eq [@billable_user.email]
              ActionMailer::Base.deliveries.last.subject.should =~ /help us shaping the right pricing/
            end

            it "creates a new MailLog record" do
              expect { subject }.to change(MailLog, :count).by(1)
            end
          end

          context "with the 'active_and_billable' filter" do
            subject { MailLetter.new(@attributes.merge(criteria: 'active_and_not_billable')).deliver_and_log }

            it "delays delivery of mails" do
              expect { subject }.to change(Delayed::Job.where(:handler.matches => "%deliver%"), :count).by(1)
            end

            it "actually sends email when workers do their jobs" do
              subject
              expect { @worker.work_off }.to change(ActionMailer::Base.deliveries, :size).by(1)
            end

            it "sends email to active and billable users and should send appropriate template" do
              ActionMailer::Base.deliveries.clear
              subject
              @worker.work_off

              ActionMailer::Base.deliveries.last.to.should eq [@user.email]
              ActionMailer::Base.deliveries.last.subject.should =~ /help us shaping the right pricing/
            end

            it "creates a new MailLog record" do
              expect { subject }.to change(MailLog, :count).by(1)
            end
          end
        end
        
      end

    end

  end

end
