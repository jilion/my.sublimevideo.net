require 'spec_helper'

describe Administration::EmailSender do

  describe ".deliver_and_log" do
    let(:admin)         { create(:admin) }
    let(:user)          { create(:user, created_at: Time.utc(2011,1,1)) }
    let(:mail_template) { create(:mail_template) }
    let(:attributes)    { { admin_id: admin.id, template_id: mail_template.id.to_s, criteria: "not_archived" } }
    let(:service)       { described_class.new(attributes) }
    before { user }
    subject { service.deliver_and_log }

    it "should save all the data" do
      expect(user).to be_beta
      expect(subject.admin).to    eq admin
      expect(subject.template).to eq mail_template
      expect(subject.criteria).to eq "not_archived"
      expect(subject.user_ids).to eq [user.id]
      expect(subject.snapshot).to eq mail_template.snapshotize
    end

    it "should keep a snapshot that doesn't change when the original template is modified" do
      subject
      old_snapshot = mail_template.snapshotize
      mail_template.reload.update(title: "foo", subject: "bar", body: "John Doe")

      expect(subject.snapshot).not_to eq mail_template.snapshotize
      expect(subject.snapshot).to eq old_snapshot
    end

    context "with multiple users to send emails to" do
      describe "with the 'dev' filter" do
        let(:service) { described_class.new(attributes.merge(criteria: 'dev')) }
        before do
          @dev_user = create(:user, email: 'remy@jilion.com')
          Sidekiq::Worker.clear_all
          ActionMailer::Base.deliveries.clear
        end

        it "delays delivery of mails" do
          expect(MailMailer).to delay(:send_mail_with_template).with(@dev_user.id, mail_template.id)
          subject
        end

        it "actually sends email when workers do their jobs" do
          subject
          expect { Sidekiq::Worker.drain_all }.to change(ActionMailer::Base.deliveries, :size).by(1)
        end

        it "sends email to user with activity sites and should send appropriate template" do
          subject
          Sidekiq::Worker.drain_all
          expect(ActionMailer::Base.deliveries.last.to).to eq [@dev_user.email]
          expect(ActionMailer::Base.deliveries.last.subject).to match(/help us shaping the right pricing/)
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
          let(:service) { described_class.new(attributes.merge(criteria: 'paying')).deliver_and_log }

          it "delays delivery of mails" do
            expect(MailMailer).to delay(:send_mail_with_template).with(@paying_user.id, mail_template.id)
            service
          end

          it "sends email when workers do their jobs" do
            service
            expect { Sidekiq::Worker.drain_all }.to change(ActionMailer::Base.deliveries, :size).by(1)
            expect(ActionMailer::Base.deliveries.map(&:to)).to match_array([[@paying_user.email]])
            expect(ActionMailer::Base.deliveries.last.subject).to match(/help us shaping the right pricing/)
          end

          it "creates a new MailLog record" do
            expect { service }.to change(MailLog, :count).by(1)
          end
        end

        context "with the 'free' filter" do
          let(:service) { described_class.new(attributes.merge(criteria: 'free')).deliver_and_log }

          it "delays delivery of mails" do
            expect(MailMailer).to delay(:send_mail_with_template).with(@free_user.id, mail_template.id)
            service
          end

          it "sends email when workers do their jobs" do
            service
            expect { Sidekiq::Worker.drain_all }.to change(ActionMailer::Base.deliveries, :size).by(2)
            expect(ActionMailer::Base.deliveries.map(&:to)).to match_array([[@free_user.email], [user.email]])
            expect(ActionMailer::Base.deliveries.last.subject).to match(/help us shaping the right pricing/)
          end

          it "creates a new MailLog record" do
            expect { service }.to change(MailLog, :count).by(1)
          end
        end
      end
    end
  end

end
