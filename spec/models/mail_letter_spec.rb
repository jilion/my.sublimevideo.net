require 'spec_helper'

describe MailLetter do

  describe "Class Methods" do
    describe "#deliver_and_log" do
      let(:admin)         { create(:admin) }
      let(:user)          { create(:user, created_at: Time.utc(2011,1,1)) }
      let(:mail_template) { create(:mail_template) }
      let(:attributes)    { { admin_id: admin.id, template_id: mail_template.id.to_s, criteria: "not_archived" } }
      let(:mail_letter)   { MailLetter.new(attributes) }
      before { user }
      subject { mail_letter.deliver_and_log }

      it "should save all the data" do
        user.should be_beta
        subject.admin.should    eq admin
        subject.template.should eq mail_template
        subject.criteria.should eq "not_archived"
        subject.user_ids.should eq [user.id]
        subject.snapshot.should eq mail_template.snapshotize
      end

      it "should keep a snapshot that doesn't change when the original template is modified" do
        subject
        old_snapshot = mail_template.snapshotize
        mail_template.reload.update_attributes(title: "foo", subject: "bar", body: "John Doe")

        subject.snapshot.should_not eq mail_template.snapshotize
        subject.snapshot.should eq old_snapshot
      end

      context "with multiple users to send emails to" do
        describe "with the 'dev' filter" do
          let(:mail_letter) { MailLetter.new(attributes.merge(criteria: 'dev')) }
          before do
            @dev_user = create(:user, email: 'remy@jilion.com')
            Sidekiq::Worker.clear_all
            ActionMailer::Base.deliveries.clear
          end

          it "delays delivery of mails" do
            MailLetter.should_receive(:deliver).with(@dev_user.id, mail_template.id)
            subject
          end

          it "actually sends email when workers do their jobs" do
            subject
            expect { Sidekiq::Worker.drain_all }.to change(ActionMailer::Base.deliveries, :size).by(1)
          end

          it "sends email to user with activity sites and should send appropriate template" do
            subject
            Sidekiq::Worker.drain_all
            ActionMailer::Base.deliveries.last.to.should eq [@dev_user.email]
            ActionMailer::Base.deliveries.last.subject.should =~ /help us shaping the right pricing/
          end

          it "doesn't create a new MailLog record" do
            expect { subject }.to_not change(MailLog, :count)
          end
        end

        describe "the 'paying', 'free' filters" do
          before do
            @archived_user  = create(:user, state: 'archived')
            @paying_user    = create(:user)
            @free_user      = create(:user)
            site = create(:site, user: @paying_user)
            create(:billable_item, site: site, item: create(:addon_plan, price: 495), state: 'subscribed')
            Sidekiq::Worker.clear_all
            ActionMailer::Base.deliveries.clear
          end

          context "with the 'paying' filter" do
            let(:mail_letter) { MailLetter.new(attributes.merge(criteria: 'paying')).deliver_and_log }

            it "delays delivery of mails" do
              MailLetter.should_receive(:deliver).with(@paying_user.id, mail_template.id)
              mail_letter
            end

            it "sends email when workers do their jobs" do
              mail_letter
              expect { Sidekiq::Worker.drain_all }.to change(ActionMailer::Base.deliveries, :size).by(1)
              ActionMailer::Base.deliveries.map(&:to).should =~ [[@paying_user.email]]
              ActionMailer::Base.deliveries.last.subject.should =~ /help us shaping the right pricing/
            end

            it "creates a new MailLog record" do
              expect { mail_letter }.to change(MailLog, :count).by(1)
            end
          end

          context "with the 'free' filter" do
            let(:mail_letter) { MailLetter.new(attributes.merge(criteria: 'free')).deliver_and_log }

            it "delays delivery of mails" do
              MailLetter.should_receive(:deliver).with(@free_user.id, mail_template.id)
              mail_letter
            end

            it "sends email when workers do their jobs" do
              mail_letter
              expect { Sidekiq::Worker.drain_all }.to change(ActionMailer::Base.deliveries, :size).by(2)
              ActionMailer::Base.deliveries.map(&:to).should =~ [[@free_user.email], [user.email]]
              ActionMailer::Base.deliveries.last.subject.should =~ /help us shaping the right pricing/
            end

            it "creates a new MailLog record" do
              expect { mail_letter }.to change(MailLog, :count).by(1)
            end
          end
        end
      end

    end
  end

end
