require 'spec_helper'

describe User do

  context "Factory" do
    before(:all) { @user = FactoryGirl.create(:user) }
    subject { @user }

    its(:terms_and_conditions) { should be_true }
    its(:first_name)           { should == "John" }
    its(:last_name)            { should == "Doe" }
    its(:full_name)            { should == "John Doe" }
    its(:country)              { should == "CH" }
    its(:postal_code)          { should == "2000" }
    its(:use_personal)         { should be_true }
    its(:newsletter)           { should be_true }
    its(:email)                { should match /email\d+@user.com/ }

    it { should be_valid }
  end

  describe "Associations" do
    before(:all) { @user = FactoryGirl.create(:user) }
    subject { @user }

    it { should have_many :sites }
    it { should have_many(:invoices).through(:sites) }
  end

  describe "Scopes" do
    before(:all) do
      User.delete_all
      # Billable because of 1 paid plan
      @user1 = FactoryGirl.create(:user)
      FactoryGirl.create(:site, user: @user1, plan_id: @paid_plan.id)
      FactoryGirl.create(:site, user: @user1, plan_id: @paid_plan.id)
      FactoryGirl.create(:site, user: @user1, plan_id: @dev_plan.id)

      # Billable because next cycle plan is another paid plan
      @user2 = FactoryGirl.create(:user)
      FactoryGirl.create(:site, user: @user2, plan_id: @paid_plan.id).update_attribute(:next_cycle_plan_id, FactoryGirl.create(:plan).id)

      # Not billable because next cycle plan is the dev plan
      @user3 = FactoryGirl.create(:user)
      FactoryGirl.create(:site, user: @user3, plan_id: @paid_plan.id).update_attribute(:next_cycle_plan_id, @dev_plan.id)

      # Not billable because his site has been archived
      @user4 = FactoryGirl.create(:user)
      FactoryGirl.create(:site, user: @user4, state: 'archived', archived_at: Time.utc(2010,2,28))

      # Billable because next cycle plan is another paid plan, but not active
      @user5 = FactoryGirl.create(:user, state: 'suspended')
      FactoryGirl.create(:site, user: @user5, plan_id: @paid_plan.id).update_attribute(:next_cycle_plan_id, FactoryGirl.create(:plan).id)

      # Not billable nor active
      @user6 = FactoryGirl.create(:user, state: 'archived')
    end

    describe ".billable" do
      specify { User.billable.select("DISTINCT users.id").order(:id).map(&:id).should =~ [@user1, @user2, @user5].map(&:id) }
    end

    describe ".not_billable" do
      specify { User.not_billable.select("DISTINCT users.id").order(:id).map(&:id).should == [@user3, @user4, @user6].map(&:id) }
    end

    describe ".active_and_billable" do
      specify { User.active_and_billable.select("DISTINCT users.id").order(:id).map(&:id).should == [@user1, @user2].map(&:id) }
    end

    describe ".active_and_not_billable" do
      specify { User.active_and_not_billable.select("DISTINCT users.id").order(:id).map(&:id).should == [@user3, @user4].map(&:id) }
    end

  end

  describe "Validations" do
    [:first_name, :last_name, :email, :remember_me, :password, :postal_code, :country, :use_personal, :use_company, :use_clients, :company_name, :company_url, :terms_and_conditions, :cc_brand, :cc_full_name, :cc_number, :cc_expiration_month, :cc_expiration_year, :cc_verification_value].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end

    # Devise checks presence/uniqueness/format of email, presence/length of password
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:postal_code) }
    it { should ensure_length_of(:postal_code).is_at_most(10) }
    it { should validate_presence_of(:country) }
    it { should validate_acceptance_of(:terms_and_conditions) }

    describe "validates uniqueness of email among non-archived users only" do
      context "email already taken by an active user" do
        it "should add an error" do
          active_user = FactoryGirl.create(:user, :state => 'active', :email => "john@doe.com")
          user = FactoryGirl.build(:user, email: active_user.email)
          user.should_not be_valid
          user.should have(1).error_on(:email)
        end
      end

      context "email already taken by an archived user" do
        it "should not add an error" do
          archived_user = FactoryGirl.create(:user, state: 'archived', email: "john@doe.com")
          user = FactoryGirl.build(:user, email: archived_user.email)
          user.should be_valid
          user.errors.should be_empty
        end
      end
    end

    it "should validate presence of at least one usage" do
      user = FactoryGirl.build(:user, :use_personal => nil, :use_company => nil, :use_clients => nil)
      user.should be_valid
    end

    it "should validate company url" do
      user = FactoryGirl.build(:user, :use_company => true, :company_url => "http://localhost")
      user.should_not be_valid
      user.should have(1).error_on(:company_url)
    end

    context "when update email" do
      it "should validate current_password presence" do
        user = FactoryGirl.create(:user)
        user.update_attributes(:email => "bob@doe.com").should be_false
        user.errors[:current_password].should == ["can't be blank"]
      end

      it "should validate current_password" do
        user = FactoryGirl.create(:user)
        user.update_attributes(:email => "bob@doe.com", :current_password => "wrong").should be_false
        user.errors[:current_password].should == ["is invalid"]
      end

      it "should not validate current_password with other errors" do
        user = FactoryGirl.create(:user)
        user.update_attributes(:password => "newone", :email => 'wrong').should be_false
        user.errors[:current_password].should be_empty
      end
    end

    context "when update password" do
      it "should validate current_password presence" do
        user = FactoryGirl.create(:user)
        user.update_attributes(:password => "newone").should be_false
        user.errors[:current_password].should == ["can't be blank"]
      end

      it "should validate current_password" do
        user = FactoryGirl.create(:user)
        user.update_attributes(:password => "newone", :current_password => "wrong").should be_false
        user.errors[:current_password].should == ["is invalid"]
      end

      it "should not validate current_password with other errors" do
        user = FactoryGirl.create(:user)
        user.update_attributes(:password => "newone", :email => '').should be_false
        user.errors[:current_password].should be_empty
      end
    end

    context "when archive" do
      it "should validate current_password presence" do
        user = FactoryGirl.create(:user)
        user.archive.should be_false
        user.errors[:current_password].should == ["can't be blank"]
      end

      it "should validate current_password" do
        user = FactoryGirl.create(:user)
        user.current_password = 'wrong'
        user.archive.should be_false
        user.errors[:current_password].should == ["is invalid"]
      end

      describe "prevent_archive_with_non_paid_invoices" do
        subject { @site.reload; @site.user.current_password = '123456'; @site.user }

        context "first invoice" do
          before(:all) do
            @site = FactoryGirl.create(:new_site, first_paid_plan_started_at: nil)
            @site.first_paid_plan_started_at.should be_nil
          end

          context "with an open invoice" do
            before(:all) do
              Invoice.delete_all
              @open_invoice = FactoryGirl.create(:invoice, site: @site, state: 'open')
            end

            it "archives the user" do
              subject.archive!.should be_true
              subject.errors[:base].should be_empty
            end
          end

          context "with a failed invoice" do
            before(:all) do
              Invoice.delete_all
              @failed_invoice = FactoryGirl.create(:invoice, site: @site, state: 'failed')
            end

            it "archives the user" do
              subject.archive!.should be_true
              subject.errors[:base].should be_empty
            end
          end

          context "with a waiting invoice" do
            before(:all) do
              Invoice.delete_all
              @waiting_invoice = FactoryGirl.create(:invoice, site: @site, state: 'waiting')
            end

            it "archives the user" do
              subject.archive.should be_false
              subject.errors[:base].should include I18n.t('activerecord.errors.models.user.attributes.base.not_paid_invoices_prevent_archive', :count => 1)
            end
          end
        end

        context "not first invoice" do
          before(:all) do
            @site = FactoryGirl.create(:new_site, first_paid_plan_started_at: Time.now.utc)
            @site.first_paid_plan_started_at.should be_present
          end

          context "with an open invoice" do
            before(:all) do
              Invoice.delete_all
              @open_invoice = FactoryGirl.create(:invoice, site: @site, state: 'open')
            end

            it "doesn't archive the user" do
              subject.archive.should be_false
              subject.errors[:base].should include I18n.t('activerecord.errors.models.user.attributes.base.not_paid_invoices_prevent_archive', :count => 1)
            end
          end

          context "with a failed invoice" do
            before(:all) do
              Invoice.delete_all
              @failed_invoice = FactoryGirl.create(:invoice, site: @site, state: 'failed')
            end

            it "doesn't archive the user" do
              subject.archive.should be_false
              subject.errors[:base].should include I18n.t('activerecord.errors.models.user.attributes.base.not_paid_invoices_prevent_archive', :count => 1)
            end
          end

          context "with a waiting invoice" do
            before(:all) do
              Invoice.delete_all
              @waiting_invoice = FactoryGirl.create(:invoice, site: @site, state: 'waiting')
            end

            it "doesn't archive the user" do
              subject.archive.should be_false
              subject.errors[:base].should include I18n.t('activerecord.errors.models.user.attributes.base.not_paid_invoices_prevent_archive', :count => 1)
            end
          end
        end
      end

    end
  end

  context "invited" do
    subject { FactoryGirl.create(:user).tap { |u| u.assign_attributes({ invitation_token: '123', invitation_sent_at: Time.now, email: "bob@bob.com", enthusiast_id: 12 }, without_protection: true); u.save(:validate => false) } }

    it "should set enthusiast_id" do
      subject.should be_invited
      subject.enthusiast_id.should == 12
    end

    it "should not be able to update enthusiast_id" do
      subject.update_attributes(:enthusiast_id => 13)
      subject.enthusiast_id.should == 12
    end
  end

  describe "State Machine" do
    before(:all) do
      @user           = FactoryGirl.create(:user)
      @dev_site       = FactoryGirl.create(:site, user: @user, plan_id: @dev_plan.id, hostname: "octavez.com")
      @paid_site      = FactoryGirl.create(:site, user: @user, hostname: "rymai.com")
      @suspended_site = FactoryGirl.create(:site, user: @user, hostname: "rymai.me", state: 'suspended')
      FactoryGirl.create(:invoice, site: @paid_site, state: 'failed')
    end

    describe "Initial State" do
      subject { @user }
      it { should be_active }
    end

    describe "#suspend" do
      before(:all) do
      end
      subject { @user }

      context "from active state" do
        it "should set user to suspended" do
          subject.reload.should be_active
          subject.suspend
          subject.should be_suspended
        end
      end

      describe "Callbacks" do
        describe "before_transition :on => :suspend, :do => :suspend_sites" do
          it "should suspend all user' active sites that have failed invoices" do
            @archived_site  = FactoryGirl.create(:site, user: @user, hostname: "rymai.tv", state: 'archived')
            @paid_site.reload.should be_active
            @dev_site.reload.should be_active
            @archived_site.reload.should be_archived
            subject.reload.suspend
            @paid_site.reload.should be_suspended
            @dev_site.reload.should be_active
            @archived_site.reload.should be_archived
          end
        end

        describe "after_transition  :on => :suspend, :do => :send_account_suspended_email" do
          it "should send an email to the user" do
            lambda { subject.reload.suspend }.should change(ActionMailer::Base.deliveries, :count).by(1)
            ActionMailer::Base.deliveries.last.to.should == [subject.email]
          end
        end
      end
    end

    describe "#unsuspend" do
      before(:each) { @user.reload.update_attribute(:state, 'suspended') }
      subject { @user }

      context "from suspended state" do
        it "should set the user to active" do
          subject.reload.should be_suspended
          subject.unsuspend
          subject.should be_active
        end
      end

      describe "Callbacks" do
        describe "before_transition :on => :unsuspend, :do => :unsuspend_sites" do
          it "should suspend all user' sites that are suspended" do
            @suspended_site.reload.should be_suspended
            @dev_site.reload.should be_active
            subject.reload.unsuspend
            @suspended_site.reload.should be_active
            @dev_site.reload.should be_active
          end
        end

        describe "after_transition  :on => :unsuspend, :do => :send_account_unsuspended_email" do
          it "should send an email to the user" do
            lambda { subject.unsuspend }.should change(ActionMailer::Base.deliveries, :count).by(1)
            ActionMailer::Base.deliveries.last.to.should == [subject.email]
          end
        end
      end
    end

    describe "#archive" do
      context "from active state" do
        before(:each) do
          @user.reload.update_attribute(:state, 'active')
          # it's impossible to archive a user that has open/waiting/failed invoices
          Invoice.delete_all
        end
        subject { @user }

        it "should require current_password" do
          subject.should be_active
          subject.current_password = nil
          subject.archive
          subject.should_not be_archived
        end

        it "should set the user to archived" do
          subject.should be_active
          subject.current_password = "123456"
          subject.archive!
          subject.should be_archived
        end
      end

      context "from suspended state" do
        before(:each) do
          @user.reload.update_attribute(:state, 'suspended')
          # it's impossible to archive a user that has open/waiting/failed invoices
          Invoice.delete_all
        end
        subject { @user }

        it "should require current_password" do
          subject.should be_suspended
          subject.current_password = nil
          subject.archive
          subject.should_not be_archived
        end

        it "should set the user to archived" do
          subject.should be_suspended
          subject.current_password = "123456"
          subject.archive!
          subject.should be_archived
        end
      end

      context "first invoice" do
        subject { @site.reload; @site.user.current_password = '123456'; @site.user }

        before(:all) do
          @site = FactoryGirl.create(:new_site, first_paid_plan_started_at: nil)
          Invoice.delete_all
          @site.first_paid_plan_started_at.should be_nil
        end

        context "with an open invoice" do
          before(:all) do
            @open_invoice = FactoryGirl.create(:invoice, site: @site, state: 'open')
          end

          it "archives the user" do
            subject.archive!.should be_true
            subject.should be_archived
            @open_invoice.reload.should be_canceled
          end
        end

        context "with a failed invoice" do
          before(:all) do
            @failed_invoice = FactoryGirl.create(:invoice, site: @site, state: 'failed')
          end

          it "archives the user" do
            subject.archive!.should be_true
            subject.should be_archived
            @failed_invoice.reload.should be_canceled
          end
        end

        context "with a waiting invoice" do
          before(:all) do
            @waiting_invoice = FactoryGirl.create(:invoice, site: @site, state: 'waiting')
          end

          it "archives the user" do
            subject.archive.should be_false
            subject.should_not be_archived
            @waiting_invoice.reload.should be_waiting
          end
        end
      end

      context "not first invoice" do
        subject { @site.reload; @site.user.current_password = '123456'; @site }
        before(:all) do
          @site = FactoryGirl.create(:new_site, first_paid_plan_started_at: Time.now.utc)
          Invoice.delete_all
          @site.first_paid_plan_started_at.should be_present
        end

        context "with an open invoice" do
          before(:all) do
            @open_invoice = FactoryGirl.create(:invoice, site: @site, state: 'open')
          end

          it "doesn't archive the user" do
            subject.archive.should be_false
            subject.should_not be_archived
            @open_invoice.reload.should be_open
          end
        end

        context "with a failed invoice" do
          before(:all) do
            @failed_invoice = FactoryGirl.create(:invoice, site: @site, state: 'failed')
          end

          it "doesn't archive the user" do
            subject.archive.should be_false
            subject.should_not be_archived
            @failed_invoice.reload.should be_failed
          end
        end

        context "with a waiting invoice" do
          before(:all) do
            @waiting_invoice = FactoryGirl.create(:invoice, site: @site, state: 'waiting')
          end

          it "doesn't archive the user" do
            subject.archive.should be_false
            subject.should_not be_archived
            @waiting_invoice.reload.should be_waiting
          end
        end
      end

      describe "Callbacks" do
        before(:each) do
          Invoice.delete_all
        end
        subject { @user.reload }

        describe "before_transition :on => :archive, :do => [:set_archived_at, :archive_sites]" do
          it "should set archived_at" do
            subject.archived_at.should be_nil
            subject.current_password = "123456"
            subject.archive
            subject.archived_at.should be_present
          end

          it "should archive each user' site" do
            subject.sites.all? { |site| site.should_not be_archived }
            subject.current_password = "123456"
            subject.archive
            subject.sites.all? { |site| site.reload.should be_archived }
          end
        end

        describe "after_transition :on => :archive, :do => [:invalidate_tokens, :newsletter_unsubscribe, :send_account_archived_email]" do
          it "invalidate all user's tokens" do
            FactoryGirl.create(:oauth2_token, user: subject)
            subject.reload.tokens.first.should_not be_invalidated_at
            subject.current_password = "123456"
            subject.archive
            subject.reload.tokens.all? { |token| token.invalidated_at? }.should be_true
          end

          it "should send an email to user" do
            expect { subject.current_password = "123456"; subject.archive }.to change(ActionMailer::Base.deliveries, :count).by(1)
            ActionMailer::Base.deliveries.last.to.should == [subject.email]
          end

          describe ":newsletter_unsubscribe" do
            use_vcr_cassette "user/newsletter_unsubscribe"
            let(:user) { FactoryGirl.create(:user, :newsletter => "1", :email => "newsletter@jilion.com") }

            it "should subscribe new email and unsubscribe old email on user destroy" do
              @worker.work_off
              CampaignMonitor.state(user.email).should == "Active"

              expect { user.current_password = "123456"; user.archive }.to change(Delayed::Job, :count).by(1)
              @worker.work_off
              CampaignMonitor.state(user.email).should == "Unsubscribed"
            end
          end
        end

      end
    end

  end

  describe "Callbacks" do
    let(:user) { FactoryGirl.create(:user) }

    describe "before_save :pend_credit_card_info" do

      context "when user had no cc infos before" do
        subject { FactoryGirl.build(:user_no_cc, valid_cc_attributes) }
        before(:each) do
          subject.save!
          subject.apply_pending_credit_card_info
          subject.reload
        end

        its(:cc_type)                { should == 'visa' }
        its(:cc_last_digits)         { should == '1111' }
        its(:cc_expire_on)           { should == 1.year.from_now.end_of_month.to_date }
        its(:pending_cc_type)        { should be_nil }
        its(:pending_cc_last_digits) { should be_nil }
        its(:pending_cc_expire_on)   { should be_nil }
      end

      context "when user has cc infos before" do
        subject { FactoryGirl.create(:user) }
        before(:each) do
          subject.cc_type.should == 'visa'
          subject.cc_last_digits.should == '1111'
          subject.cc_expire_on.should == 1.year.from_now.end_of_month.to_date
          subject.attributes = valid_cc_attributes_master
          subject.save!
          subject.apply_pending_credit_card_info
          subject.reload
        end

        its(:cc_type)                { should == 'master' }
        its(:cc_last_digits)         { should == '9999' }
        its(:cc_expire_on)           { should == 2.years.from_now.end_of_month.to_date }
        its(:pending_cc_type)        { should be_nil }
        its(:pending_cc_last_digits) { should be_nil }
        its(:pending_cc_expire_on)   { should be_nil }
      end
    end

    describe "after_save :newsletter_update" do
      use_vcr_cassette "campaign_monitor/user"
      let(:user) { FactoryGirl.create(:user, :newsletter => "1", :email => "newsletter@jilion.com") }

      it "should subscribe on user creation" do
        expect { user }.to change(Delayed::Job, :count).by(1)
        @worker.work_off
        CampaignMonitor.state(user.email).should == "Active"
      end

      it "should not subscribe on user creation if newsletter is false" do
        user = FactoryGirl.create(:user, :newsletter => "0", :email => "no_newsletter@jilion.com")
        @worker.work_off
        CampaignMonitor.state(user.email).should == "Unknown"
      end

      it "should subscribe new email and unsubscribe old email on user email update" do
        old_email = user.email
        @worker.work_off
        CampaignMonitor.state(user.email).should == "Active"
        expect { user.update_attribute(:email, "new@jilion.com") }.to change(Delayed::Job, :count).by(1)
        @worker.work_off
        CampaignMonitor.state(old_email).should == "Unsubscribed"
        CampaignMonitor.state(user.email).should == "Active"
      end

      it "should update infos in Campaign Monitor if user just change his name" do
        user
        @worker.work_off
        expect { user.update_attribute(:first_name, "bob") }.to change(Delayed::Job, :count).by(1)
      end
    end

    describe "after_update :zendesk_update" do
      context "user has no zendesk_id" do

        it "should not delay Module#put" do
          expect { user.update_attribute(:email, "new@jilion.com") }.to change(Delayed::Job, :count).by(2)
          Delayed::Job.all.any? { |dj| dj.name == 'Module#put' }.should be_false
        end

      end

      context "user has a zendesk_id" do
        before(:each) do
          user.update_attribute(:zendesk_id, 59438671)
        end

        it "should delay Module#put if the user has a zendesk_id and his email has changed" do
          expect { user.update_attribute(:email, "new@jilion.com") }.to change(Delayed::Job, :count).by(2)
          Delayed::Job.all.any? { |dj| dj.name == 'Module#put' }.should be_true
        end

        it "should update user's email on Zendesk if this user has a zendesk_id and his email has changed" do
          expect { user.update_attribute(:email, "new@jilion.com") }.to change(Delayed::Job, :count).by(2)

          VCR.use_cassette("user/update_email_on_zendesk") do
            @worker.work_off
            Delayed::Job.last.should be_nil
            JSON[Zendesk.get("/users/59438671/user_identities.json").body].select { |h| h["identity_type"] == "email" }.map { |h| h["value"] }.should include("new@jilion.com")
          end
        end

        it "should update user's email on Zendesk if this user has a zendesk_id and his first name has changed" do
          expect { user.update_attribute(:first_name, "Remy") }.to change(Delayed::Job, :count).by(2)

          VCR.use_cassette("user/update_first_name_on_zendesk") do
            @worker.work_off
            Delayed::Job.last.should be_nil
            JSON[Zendesk.get("/users/59438671.json").body]['name'].should include("Remy")
          end
        end

        it "should update user's email on Zendesk if this user has a zendesk_id and his last name has changed" do
          expect { user.update_attribute(:last_name, "Coutable") }.to change(Delayed::Job, :count).by(2)

          VCR.use_cassette("user/update_last_name_on_zendesk") do
            @worker.work_off
            Delayed::Job.last.should be_nil
            JSON[Zendesk.get("/users/59438671.json").body]['name'].should include("Coutable")
          end
        end

      end
    end

  end

  describe "attributes accessor" do
    describe "email=" do
      it "should downcase email" do
        user = FactoryGirl.build(:user, email: "BOB@cool.com")
        user.email.should == "bob@cool.com"
      end
    end
  end

  describe "Instance Methods" do
    let(:user) { FactoryGirl.create(:user) }

    describe "#active_for_authentication?" do
      it "should be active for authentication when active" do
        user.should be_active_for_authentication
      end

      it "should be active for authentication when suspended in order to allow login" do
        user.suspend
        user.should be_active_for_authentication
      end

      it "should not be active for authentication when archived" do
        user.archive
        user.should be_active_for_authentication
      end
    end

    describe "#have_beta_sites?" do
      before(:all) { @site = FactoryGirl.create(:site, plan_id: @beta_plan.id) }

      specify { @site.user.have_beta_sites?.should be_true }

      context "with archived beta site" do
        before(:all) do
          @site = FactoryGirl.create(:site, plan_id: @beta_plan.id)
          @site.archive
        end

        specify { @site.user.have_beta_sites?.should be_false }
      end
    end

    describe "#beta?" do
      context "with active beta user" do
        subject { FactoryGirl.create(:user, created_at: Time.utc(2010,10,10), invitation_token: nil) }

        its(:beta?) { should be_true }
      end
      context "with un active beta user" do
        subject { FactoryGirl.create(:user, created_at: Time.utc(2010,10,10), invitation_token: 'xxx') }

        its(:beta?) { should be_false }
      end
      context "with a standard user (limit)" do
        subject { FactoryGirl.create(:user, created_at: Time.utc(2011,3,29).midnight, invitation_token: nil) }

        its(:beta?) { should be_false }
      end
      context "with a standard user" do
        subject { FactoryGirl.create(:user, created_at: Time.utc(2011,3,30), invitation_token: nil) }

        its(:beta?) { should be_false }
      end
    end

    describe "#vat?" do
      context "with Swiss user" do
        subject { FactoryGirl.create(:user, country: 'CH') }

        its(:vat?) { should be_true }
      end
      context "with USA user" do
        subject { FactoryGirl.create(:user, country: 'US') }

        its(:vat?) { should be_false }
      end
    end

    describe "#invoices_failed?" do
      before(:all) do
        @user = FactoryGirl.create(:user)
        @site = FactoryGirl.create(:site, user: @user)
        FactoryGirl.create(:invoice, state: 'failed', site: @site)
      end
      subject { @user }

      its(:invoices_failed?) { should be_true }
    end

    describe "#invoices_waiting?" do
      before(:all) do
        @user = FactoryGirl.create(:user)
        @site = FactoryGirl.create(:site, user: @user)
        FactoryGirl.create(:invoice, state: 'waiting', site: @site)
      end
      subject { @user }

      its(:invoices_waiting?) { should be_true }
    end

    describe "#invoices_open?" do
      before(:all) do
        @user = FactoryGirl.create(:user)
        @site = FactoryGirl.create(:site, user: @user)
      end
      before(:each) do
        Invoice.delete_all
      end
      subject { @user }

      context "with no options" do
        it "should be true if invoice have the renew flag == false" do
          invoice = FactoryGirl.create(:invoice, state: 'open', site: @site, renew: false)
          invoice.renew.should be_false
          subject.invoices_open?.should be_true
        end

        it "should be true if invoice have the renew flag == true" do
          invoice = FactoryGirl.create(:invoice, state: 'open', site: @site, renew: true)
          invoice.renew.should be_true
          subject.invoices_open?.should be_true
        end
      end

      context "with options[:renew] == true" do
        it "should be false if no invoice with the renew flag == true" do
          invoice = FactoryGirl.create(:invoice, state: 'open', site: @site, renew: false)
          invoice.renew.should be_false
          subject.invoices_open?(renew: true).should be_false
        end

        it "should be true if invoice with the renew flag == true" do
          invoice = FactoryGirl.create(:invoice, state: 'open', site: @site, renew: true)
          invoice.renew.should be_true
          subject.invoices_open?(renew: true).should be_true
        end
      end

      context "with options[:renew] == false" do
        it "should be false if no invoice with the renew flag == true" do
          invoice = FactoryGirl.create(:invoice, state: 'open', site: @site, renew: false)
          invoice.renew.should be_false
          subject.invoices_open?(renew: false).should be_true
        end

        it "should be true if invoice with the renew flag == true" do
          invoice = FactoryGirl.create(:invoice, state: 'open', site: @site, renew: true)
          invoice.renew.should be_true
          subject.invoices_open?(renew: false).should be_false
        end
      end
    end

    describe "#support" do
      context "user has no site" do
        before(:all) do
          @user = FactoryGirl.create(:user)
        end
        subject { @user.reload }

        it { subject.support.should == "launchpad" }
      end

      context "user has a site with no plan" do
        before(:all) do
          @user = FactoryGirl.create(:user)
          @site = FactoryGirl.create(:site, user: @user)
          @site.send(:write_attribute, :plan_id, nil)
          @site.save(validate: false)
          @site.plan_id.should be_nil
        end
        subject { @user.reload }

        it { subject.support.should == "launchpad" }
      end

      context "user has only sites with launchpad support" do
        before(:all) do
          @user = FactoryGirl.create(:user)
          FactoryGirl.create(:site, user: @user, plan_id: @dev_plan.id)
        end
        subject { @user.reload }

        it { @dev_plan.support.should == "launchpad" }
        it { subject.support.should == "launchpad" }
      end

      context "user has only sites with standard support" do
        before(:all) do
          @user = FactoryGirl.create(:user)
          FactoryGirl.create(:site, user: @user, plan_id: @paid_plan.id)
          FactoryGirl.create(:site, user: @user, plan_id: @beta_plan.id)
        end
        subject { @user.reload }

        it { @paid_plan.support.should == "standard" }
        it { @beta_plan.support.should == "standard" }
        it { subject.support.should == "standard" }
      end

      context "user has at least one site with priority support" do
        before(:all) do
          @user = FactoryGirl.create(:user)
          FactoryGirl.create(:site, user: @user, plan_id: @paid_plan.id)
          FactoryGirl.create(:site, user: @user, plan_id: @custom_plan.token)
        end
        subject { @user.reload }

        it { @paid_plan.support.should == "standard" }
        it { @custom_plan.support.should == "priority" }
        it { subject.support.should == "priority" }
      end
    end

    describe "#archivable?" do
      subject { @site.reload; @site.user }

      context "first invoice" do
        before(:all) do
          Invoice.delete_all
          @site = FactoryGirl.create(:new_site, first_paid_plan_started_at: nil)
          @site.first_paid_plan_started_at.should be_nil
        end

        context "with an open invoice" do
          before(:all) do
            @open_invoice = FactoryGirl.create(:invoice, site: @site, state: 'open')
          end

          it { should be_archivable }
        end

        context "with a failed invoice" do
          before(:all) do
            @failed_invoice = FactoryGirl.create(:invoice, site: @site, state: 'failed')
          end

          it { should be_archivable }
        end

        context "with a waiting invoice" do
          before(:all) do
            @waiting_invoice = FactoryGirl.create(:invoice, site: @site, state: 'waiting')
          end

          it { should_not be_archivable }
        end
      end

      context "not first invoice" do
        before(:all) do
          Invoice.delete_all
          @site = FactoryGirl.create(:new_site, first_paid_plan_started_at: Time.now.utc)
          @site.first_paid_plan_started_at.should be_present
        end

        context "with an open invoice" do
          before(:all) do
            @open_invoice = FactoryGirl.create(:invoice, site: @site, state: 'open')
          end

          it { should_not be_archivable }
        end

        context "with a failed invoice" do
          before(:all) do
            @failed_invoice = FactoryGirl.create(:invoice, site: @site, state: 'failed')
          end

          it { should_not be_archivable }
        end

        context "with a waiting invoice" do
          before(:all) do
            @waiting_invoice = FactoryGirl.create(:invoice, site: @site, state: 'waiting')
          end

          it { should_not be_archivable }
        end
      end
    end

  end

  def accept_invitation(attributes = {})
    default = {
      :password => "123456",
      :first_name => "John",
      :last_name => "Doe",
      :country => "CH",
      :postal_code => "2000",
      :use_company => true,
      :company_name => "bob",
      :company_url => "bob.com",
      :terms_and_conditions => "1",
      :invitation_token => @user.invitation_token
    }
    User.accept_invitation(default.merge(attributes))
  end

end






# == Schema Information
#
# Table name: users
#
#  id                     :integer         not null, primary key
#  state                  :string(255)
#  email                  :string(255)     default(""), not null
#  encrypted_password     :string(128)     default(""), not null
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer         default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  failed_attempts        :integer         default(0)
#  locked_at              :datetime
#  cc_type                :string(255)
#  cc_last_digits         :string(255)
#  cc_expire_on           :date
#  cc_updated_at          :datetime
#  created_at             :datetime
#  updated_at             :datetime
#  invitation_token       :string(20)
#  invitation_sent_at     :datetime
#  zendesk_id             :integer
#  enthusiast_id          :integer
#  first_name             :string(255)
#  last_name              :string(255)
#  postal_code            :string(255)
#  country                :string(255)
#  use_personal           :boolean
#  use_company            :boolean
#  use_clients            :boolean
#  company_name           :string(255)
#  company_url            :string(255)
#  company_job_title      :string(255)
#  company_employees      :string(255)
#  company_videos_served  :string(255)
#  cc_alias               :string(255)
#  pending_cc_type        :string(255)
#  pending_cc_last_digits :string(255)
#  pending_cc_expire_on   :date
#  pending_cc_updated_at  :datetime
#  archived_at            :datetime
#  newsletter             :boolean         default(TRUE)
#  last_invoiced_amount   :integer         default(0)
#  total_invoiced_amount  :integer         default(0)
#
# Indexes
#
#  index_users_on_cc_alias               (cc_alias) UNIQUE
#  index_users_on_confirmation_token     (confirmation_token) UNIQUE
#  index_users_on_created_at             (created_at)
#  index_users_on_current_sign_in_at     (current_sign_in_at)
#  index_users_on_email_and_archived_at  (email,archived_at) UNIQUE
#  index_users_on_last_invoiced_amount   (last_invoiced_amount)
#  index_users_on_reset_password_token   (reset_password_token) UNIQUE
#  index_users_on_total_invoiced_amount  (total_invoiced_amount)
#

