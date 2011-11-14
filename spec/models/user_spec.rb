# coding: utf-8
require 'spec_helper'

describe User do

  let(:full_billing_address) do
    { billing_address_1: "EPFL Innovation Square", billing_address_2: "PSE-D", billing_postal_code: "1015", billing_city: "New York", billing_region: "NY", billing_country: "US" }
  end

  context "Factory" do
    before(:all) { @user = Factory.create(:user) }
    subject { @user }

    its(:terms_and_conditions) { should be_true }
    its(:name)                 { should eq "John Doe" }
    its(:billing_name)         { should eq "Remy Coutable" }
    its(:billing_address_1)    { should eq "Avenue de France 71" }
    its(:billing_address_2)    { should eq "Batiment B" }
    its(:billing_postal_code)  { should eq "1004" }
    its(:billing_city)         { should eq "Lausanne" }
    its(:billing_region)       { should eq "VD" }
    its(:billing_country)      { should eq "CH" }
    its(:use_personal)         { should be_true }
    its(:newsletter)           { should be_true }
    its(:email)                { should match /email\d+@user.com/ }
    its(:hidden_notice_ids)    { should eq [] }

    it { should be_valid }
  end

  describe "Associations" do
    before(:all) { @user = Factory.create(:user) }
    subject { @user }

    it { should have_many :sites }
    it { should have_many(:invoices).through(:sites) }
    it { should have_one(:last_invoice).through(:sites) }
    it { should have_many :client_applications }
    it { should have_many :tokens }
  end

  describe "Validations" do
    [:name, :email, :remember_me, :password, :billing_address_1, :billing_address_2, :billing_postal_code, :billing_city, :billing_region, :billing_country, :use_personal, :use_company, :use_clients, :company_name, :company_url, :terms_and_conditions, :hidden_notice_ids, :cc_register, :cc_brand, :cc_full_name, :cc_number, :cc_expiration_month, :cc_expiration_year, :cc_verification_value].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end

    # Devise checks presence/uniqueness/format of email, presence/length of password
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:name) }
    it { should ensure_length_of(:billing_postal_code).is_at_most(10) }
    it { should validate_acceptance_of(:terms_and_conditions) }

    describe "email" do
      context "email already taken by an active user" do
        it "is not valid" do
          active_user = Factory.create(:user, state: 'active', email: "john@doe.com")
          user = Factory.build(:user, email: active_user.email)
          user.should_not be_valid
          user.should have(1).error_on(:email)
        end
      end

      context "email already taken by an archived user" do
        it "is valid" do
          archived_user = Factory.create(:user, state: 'archived', email: "john@doe.com")
          user = Factory.build(:user, email: archived_user.email)
          user.should be_valid
        end
      end
    end

    describe "billing_country" do
      before(:all) do
        Site.delete_all
        @billable_user = Factory.create(:user)
        @non_billable_user = Factory.create(:user)

        # billable
        Factory.create(:site, user: @billable_user, plan_id: @paid_plan.id)

        # not billable
        Factory.create(:site, user: @non_billable_user, plan_id: @free_plan.id)
      end

      context "user is not billable" do
        it "is not valid" do
          @billable_user.billing_country = ''
          @billable_user.should_not be_valid
          @billable_user.should have(1).error_on(:billing_country)
        end
      end

      context "user is billable" do
        it "is valid" do
          @non_billable_user.billing_country = ''
          @non_billable_user.should be_valid
        end
      end
    end

    describe "company_url" do
      context "is present" do
        it "is not valid" do
          user = Factory.build(:user, use_company: true, company_url: "http://localhost")
          user.should_not be_valid
          user.should have(1).error_on(:company_url)
        end
      end

      context "is not present" do
        it "is valid" do
          user = Factory.build(:user, use_company: true, company_url: "")
          user.should be_valid
        end
      end
    end

    context "when update email" do
      it "should validate current_password presence" do
        user = Factory.create(:user)
        user.update_attributes(email: "bob@doe.com").should be_false
        user.errors[:current_password].should eq ["can't be blank"]
      end

      it "should validate current_password" do
        user = Factory.create(:user)
        user.update_attributes(email: "bob@doe.com", current_password: "wrong").should be_false
        user.errors[:current_password].should eq ["is invalid"]
      end

      it "should not validate current_password with other errors" do
        user = Factory.create(:user)
        user.update_attributes(password: "newone", email: 'wrong').should be_false
        user.errors[:current_password].should be_empty
      end
    end

    context "when update password" do
      it "should validate current_password presence" do
        user = Factory.create(:user)
        user.update_attributes(password: "newone").should be_false
        user.errors[:current_password].should eq ["can't be blank"]
      end

      it "should validate current_password" do
        user = Factory.create(:user)
        user.update_attributes(password: "newone", current_password: "wrong").should be_false
        user.errors[:current_password].should eq ["is invalid"]
      end

      it "should not validate current_password with other errors" do
        user = Factory.create(:user)
        user.update_attributes(password: "newone", email: '').should be_false
        user.errors[:current_password].should be_empty
      end
    end

    context "when archive" do
      it "should validate current_password presence" do
        user = Factory.create(:user)
        user.archive.should be_false
        user.errors[:current_password].should eq ["can't be blank"]
      end

      it "should validate current_password" do
        user = Factory.create(:user)
        user.current_password = 'wrong'
        user.archive.should be_false
        user.errors[:current_password].should eq ["is invalid"]
      end

      describe "prevent_archive_with_non_paid_invoices" do
        subject { @site.reload; @site.user.current_password = '123456'; @site.user }

        context "first invoice" do
          before(:all) do
            @site = Factory.create(:new_site, first_paid_plan_started_at: nil)
            @site.first_paid_plan_started_at.should be_nil
          end

          context "with an open invoice" do
            before(:all) do
              Invoice.delete_all
              @open_invoice = Factory.create(:invoice, site: @site, state: 'open')
            end

            it "archives the user" do
              subject.archive!.should be_true
              subject.errors[:base].should be_empty
            end
          end

          context "with a failed invoice" do
            before(:all) do
              Invoice.delete_all
              @failed_invoice = Factory.create(:invoice, site: @site, state: 'failed')
            end

            it "archives the user" do
              subject.archive!.should be_true
              subject.errors[:base].should be_empty
            end
          end

          context "with a waiting invoice" do
            before(:all) do
              Invoice.delete_all
              @waiting_invoice = Factory.create(:invoice, site: @site, state: 'waiting')
            end

            it "archives the user" do
              subject.archive.should be_false
              subject.errors[:base].should include I18n.t('activerecord.errors.models.user.attributes.base.not_paid_invoices_prevent_archive', count: 1)
            end
          end
        end

        context "not first invoice" do
          before(:all) do
            @site = Factory.create(:new_site, first_paid_plan_started_at: Time.now.utc)
            @site.first_paid_plan_started_at.should be_present
          end

          context "with an open invoice" do
            before(:all) do
              Invoice.delete_all
              @open_invoice = Factory.create(:invoice, site: @site, state: 'open')
            end

            it "doesn't archive the user" do
              subject.archive.should be_false
              subject.errors[:base].should include I18n.t('activerecord.errors.models.user.attributes.base.not_paid_invoices_prevent_archive', count: 1)
            end
          end

          context "with a failed invoice" do
            before(:all) do
              Invoice.delete_all
              @failed_invoice = Factory.create(:invoice, site: @site, state: 'failed')
            end

            it "doesn't archive the user" do
              subject.archive.should be_false
              subject.errors[:base].should include I18n.t('activerecord.errors.models.user.attributes.base.not_paid_invoices_prevent_archive', count: 1)
            end
          end

          context "with a waiting invoice" do
            before(:all) do
              Invoice.delete_all
              @waiting_invoice = Factory.create(:invoice, site: @site, state: 'waiting')
            end

            it "doesn't archive the user" do
              subject.archive.should be_false
              subject.errors[:base].should include I18n.t('activerecord.errors.models.user.attributes.base.not_paid_invoices_prevent_archive', count: 1)
            end
          end
        end
      end

    end
  end

  context "invited" do
    subject { Factory.create(:user).tap { |u| u.assign_attributes({ invitation_token: '123', invitation_sent_at: Time.now, email: "bob@bob.com", enthusiast_id: 12 }, without_protection: true); u.save(validate: false) } }

    it "should set enthusiast_id" do
      subject.should be_invited
      subject.enthusiast_id.should == 12
    end

    it "should not be able to update enthusiast_id" do
      subject.update_attributes(enthusiast_id: 13)
      subject.enthusiast_id.should == 12
    end
  end

  describe "State Machine" do
    before(:all) do
      @user           = Factory.create(:user)
      @free_site      = Factory.create(:site, user: @user, plan_id: @free_plan.id, hostname: "octavez.com")
      @paid_site      = Factory.create(:site, user: @user, hostname: "rymai.com")
      @suspended_site = Factory.create(:site, user: @user, hostname: "rymai.me", state: 'suspended')
      Factory.create(:invoice, site: @paid_site, state: 'failed')
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
        describe "before_transition on: :suspend, do: :suspend_sites" do
          it "should suspend all user' active sites that have failed invoices" do
            @archived_site  = Factory.create(:site, user: @user, hostname: "rymai.tv", state: 'archived')
            @paid_site.reload.should be_active
            @free_site.reload.should be_active
            @archived_site.reload.should be_archived
            subject.reload.suspend
            @paid_site.reload.should be_suspended
            @free_site.reload.should be_active
            @archived_site.reload.should be_archived
          end
        end

        describe "after_transition  on: :suspend, do: :send_account_suspended_email" do
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
        describe "before_transition on: :unsuspend, do: :unsuspend_sites" do
          it "should suspend all user' sites that are suspended" do
            @suspended_site.reload.should be_suspended
            @free_site.reload.should be_active
            subject.reload.unsuspend
            @suspended_site.reload.should be_active
            @free_site.reload.should be_active
          end
        end

        describe "after_transition  on: :unsuspend, do: :send_account_unsuspended_email" do
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
          @site = Factory.create(:new_site, first_paid_plan_started_at: nil)
          Invoice.delete_all
          @site.first_paid_plan_started_at.should be_nil
        end

        context "with an open invoice" do
          before(:all) do
            @open_invoice = Factory.create(:invoice, site: @site, state: 'open')
          end

          it "archives the user" do
            subject.archive!.should be_true
            subject.should be_archived
            @open_invoice.reload.should be_canceled
          end
        end

        context "with a failed invoice" do
          before(:all) do
            @failed_invoice = Factory.create(:invoice, site: @site, state: 'failed')
          end

          it "archives the user" do
            subject.archive!.should be_true
            subject.should be_archived
            @failed_invoice.reload.should be_canceled
          end
        end

        context "with a waiting invoice" do
          before(:all) do
            @waiting_invoice = Factory.create(:invoice, site: @site, state: 'waiting')
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
          @site = Factory.create(:new_site, first_paid_plan_started_at: Time.now.utc)
          Invoice.delete_all
          @site.first_paid_plan_started_at.should be_present
        end

        context "with an open invoice" do
          before(:all) do
            @open_invoice = Factory.create(:invoice, site: @site, state: 'open')
          end

          it "doesn't archive the user" do
            subject.archive.should be_false
            subject.should_not be_archived
            @open_invoice.reload.should be_open
          end
        end

        context "with a failed invoice" do
          before(:all) do
            @failed_invoice = Factory.create(:invoice, site: @site, state: 'failed')
          end

          it "doesn't archive the user" do
            subject.archive.should be_false
            subject.should_not be_archived
            @failed_invoice.reload.should be_failed
          end
        end

        context "with a waiting invoice" do
          before(:all) do
            @waiting_invoice = Factory.create(:invoice, site: @site, state: 'waiting')
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

        describe "before_transition on: :archive, do: [:set_archived_at, :archive_sites]" do
          it "sets archived_at" do
            subject.archived_at.should be_nil
            subject.current_password = "123456"
            subject.archive
            subject.archived_at.should be_present
          end

          it "archives each user' site" do
            subject.sites.all? { |site| site.should_not be_archived }
            subject.current_password = "123456"
            subject.archive
            subject.sites.all? { |site| site.reload.should be_archived }
          end
        end

        describe "after_transition on: :archive, do: [:invalidate_tokens, :newsletter_unsubscribe, :send_account_archived_email]" do
          it "invalidates all user's tokens" do
            Factory.create(:oauth2_token, user: subject)
            subject.reload.tokens.first.should_not be_invalidated_at
            subject.current_password = "123456"
            subject.archive
            subject.reload.tokens.all? { |token| token.invalidated_at? }.should be_true
          end

          it "sends an email to user" do
            subject.current_password = "123456"
            expect { subject.archive }.to change(ActionMailer::Base.deliveries, :count).by(1)
            ActionMailer::Base.deliveries.last.to.should eq [subject.email]
          end

          describe ":newsletter_unsubscribe" do
            use_vcr_cassette "user/newsletter_unsubscribe"
            subject { Factory.create(:user, newsletter: "1", email: "john@doe.com") }

            it "subscribes new email and unsubscribe old email on user destroy" do
              subject # explicitly create the subject
              @worker.work_off
              CampaignMonitor.subscriber(subject.email)["State"].should eq "Active"

              subject.current_password = "123456"
              expect { subject.archive }.to change(Delayed::Job, :count).by(1)
              @worker.work_off

              CampaignMonitor.subscriber(subject.email)["State"].should eq "Unsubscribed"
            end
          end
        end

      end
    end

  end

  describe "Callbacks" do

    describe "before_save :prepare_pending_credit_card" do

      context "when user had no cc infos before" do
        subject { Factory.create(:user_no_cc, valid_cc_attributes.merge(cc_register: false)) }

        its(:cc_type)                { should be_nil }
        its(:cc_last_digits)         { should be_nil }
        its(:cc_expire_on)           { should be_nil }
        its(:pending_cc_type)        { should eq 'visa' }
        its(:pending_cc_last_digits) { should eq '1111' }
        its(:pending_cc_expire_on)   { should eq 1.year.from_now.end_of_month.to_date }
      end

      context "when user has cc infos before" do
        subject { Factory.create(:user_real_cc) }
        before(:each) do
          subject.cc_type.should eq 'visa'
          subject.cc_last_digits.should eq '1111'
          subject.cc_expire_on.should eq 1.year.from_now.end_of_month.to_date

          subject.attributes = valid_cc_attributes_master.merge(cc_register: false)
          subject.save!
        end

        its(:cc_type)                { should eq 'visa' }
        its(:cc_last_digits)         { should eq '1111' }
        its(:cc_expire_on)           { should eq 1.year.from_now.end_of_month.to_date }
        its(:pending_cc_type)        { should eq 'master' }
        its(:pending_cc_last_digits) { should eq '9999' }
        its(:pending_cc_expire_on)   { should eq 2.years.from_now.end_of_month.to_date }
      end
    end

    describe "after_save :newsletter_update" do
      context "user sign-up" do
        context "user subscribes on sign-up" do
          subject { Factory.create(:user, newsletter: "1", email: "newsletter_sign_up@jilion.com") }

          it "registers user's email on Campaign Monitor" do
            expect { subject }.to change(Delayed::Job, :count).by(1)
            Delayed::Job.last.name.should eql "Class#subscribe"
          end
        end

        context "user doesn't subscribe on sign-up" do
          subject { Factory.create(:user, newsletter: "0", email: "no_newsletter_sign_up@jilion.com") }

          it "doesn't register user's email on Campaign Monitor" do
            expect { subject }.to_not change(Delayed::Job, :count)
          end
        end
      end

      context "user update" do
        subject { Factory.create(:user, newsletter: "1", email: "newsletter_update@jilion.com") }

        it "registers user's new email on Campaign Monitor and remove old email when user update his email" do
          subject
          expect { subject.update_attribute(:email, "newsletter_update2@jilion.com") }.to change(Delayed::Job, :count).by(1)
          Delayed::Job.last.name.should eql "Class#update"
        end

        it "updates infos in Campaign Monitor if user change his name" do
          subject
          expect { subject.update_attribute(:name, "bob") }.to change(Delayed::Job, :count).by(1)
          Delayed::Job.last.name.should eql "Class#update"
        end

        it "updates subscribing state in Campaign Monitor if user change his newsletter state" do
          subject
          expect { subject.update_attribute(:newsletter, false) }.to change(Delayed::Job, :count).by(2)
          djs = Delayed::Job.limit(2).order(:created_at.desc).all
          djs[0].name.should eql "Class#unsubscribe"
          djs[1].name.should eql "Class#update"
        end
      end
    end

    describe "after_update :zendesk_update" do
      subject { Factory.create(:user) }
      before(:each) do
        CampaignMonitor.stub(:subscribe)
        CampaignMonitor.stub(:update)
      end

      context "user has no zendesk_id" do
        it "should not delay Module#put" do
          expect { subject.update_attribute(:email, "new@jilion.com") }.to change(Delayed::Job, :count).by(2)
          Delayed::Job.all.any? { |dj| dj.name == 'Module#put' }.should be_false
        end
      end

      context "user has a zendesk_id" do
        before(:each) do
          subject.update_attribute(:zendesk_id, 59438671)
        end

        it "should delay Module#put if the user has a zendesk_id and his email has changed" do
          expect { subject.update_attribute(:email, "new@jilion.com") }.to change(Delayed::Job, :count).by(2)
          Delayed::Job.all.select { |dj| dj.name == 'Module#put' }.should have(1).item
        end

        it "should update user's email on Zendesk if this user has a zendesk_id and his email has changed" do
          expect { subject.update_attribute(:email, "new@jilion.com") }.to change(Delayed::Job, :count).by(2)

          VCR.use_cassette("zendesk/update_email") do
            @worker.work_off
            Delayed::Job.last.should be_nil
            JSON[Zendesk.get("/users/59438671/user_identities.json").body].select { |h| h["identity_type"] == "email" }.map { |h| h["value"] }.should include("new@jilion.com")
          end
        end

        it "should update user's name on Zendesk if this user has a zendesk_id and his name has changed" do
          expect { subject.update_attribute(:name, "Remy") }.to change(Delayed::Job, :count).by(2)

          VCR.use_cassette("zendesk/update_name") do
            @worker.work_off
            Delayed::Job.last.should be_nil
            JSON[Zendesk.get("/users/59438671.json").body]['name'].should eq "Remy"
          end
        end

      end
    end

  end

  describe "attributes accessor" do
    subject { Factory.create(:user, email: "BoB@CooL.com") }

    describe "email=" do
      it "downcases email" do
        subject.email.should eq "bob@cool.com"
      end
    end

    describe "hidden_notice_ids" do
      it "initialize as an array if nil" do
        subject.hidden_notice_ids.should eq []
      end

      it "doesn't cast given value" do
        subject.hidden_notice_ids << 1 << "foo"
        subject.hidden_notice_ids.should eq [1, "foo"]
      end
    end
  end

  describe "Instance Methods" do
    subject { Factory.create(:user) }

    describe "#notice_hidden?" do
      before(:each) do
        subject.hidden_notice_ids << 1
        subject.hidden_notice_ids.should eq [1]
      end

      specify { subject.notice_hidden?(1).should be_true }
      specify { subject.notice_hidden?("1").should be_true }
      specify { subject.notice_hidden?(2).should be_false }
      specify { subject.notice_hidden?('foo').should be_false }
    end

    describe "#active_for_authentication?" do
      it "should be active for authentication when active" do
        subject.should be_active_for_authentication
      end

      it "should be active for authentication when suspended in order to allow login" do
        subject.suspend
        subject.should be_active_for_authentication
      end

      it "should not be active for authentication when archived" do
        subject.archive
        subject.should be_active_for_authentication
      end
    end

    describe "#beta?" do
      context "with active beta user" do
        subject { Factory.create(:user, created_at: Time.utc(2010,10,10), invitation_token: nil) }

        its(:beta?) { should be_true }
      end
      context "with un active beta user" do
        subject { Factory.create(:user, created_at: Time.utc(2010,10,10), invitation_token: 'xxx') }

        its(:beta?) { should be_false }
      end
      context "with a standard user (limit)" do
        subject { Factory.create(:user, created_at: Time.utc(2011,3,29).midnight, invitation_token: nil) }

        its(:beta?) { should be_false }
      end
      context "with a standard user" do
        subject { Factory.create(:user, created_at: Time.utc(2011,3,30), invitation_token: nil) }

        its(:beta?) { should be_false }
      end
    end

    describe "#vat?" do
      context "with Swiss user" do
        subject { Factory.create(:user, billing_country: 'CH') }

        its(:vat?) { should be_true }
      end

      context "with USA user" do
        subject { Factory.create(:user, billing_country: 'US') }

        its(:vat?) { should be_false }
      end
    end

    describe "#billing_address" do
      context "delegates to snail using billing infos" do
        subject { Factory.create(:user, full_billing_address) }

        its(:billing_address) { should eq "Remy Coutable\nEPFL Innovation Square\nPSE-D\nNew York NY  1015\nUNITED STATES" }
      end

      context "billing_name is missing" do
        subject { Factory.create(:user, full_billing_address.merge(billing_name: "")) }

        its(:billing_address) { should eq "John Doe\nEPFL Innovation Square\nPSE-D\nNew York NY  1015\nUNITED STATES" }
      end

      context "billing_postal_code is missing" do
        subject { Factory.create(:user, full_billing_address.merge(billing_postal_code: "")) }

        its(:billing_address) { should eq "Remy Coutable\nEPFL Innovation Square\nPSE-D\nNew York NY  \nUNITED STATES" }
      end

      context "billing_country is missing" do
        subject { Factory.create(:user, full_billing_address.merge(billing_country: "")) }

        its(:billing_address) { should eq "Remy Coutable\nEPFL Innovation Square\nPSE-D\nNew York NY  1015" }
      end
    end

    describe "#billing_address_complete?" do
      context "complete billing address" do
        subject { Factory.create(:user, full_billing_address) }

        it { should be_billing_address_complete }
      end

      context "billing address is missing billing_address_2" do
        subject { Factory.create(:user, full_billing_address.merge(billing_address_2: "")) }

        it { should be_billing_address_complete }
      end

      context "billing address is missing billing_region" do
        subject { Factory.create(:user, full_billing_address.merge(billing_region: "")) }

        it { should be_billing_address_complete }
      end

      context "billing address is missing billing_address_1" do
        subject { Factory.create(:user, full_billing_address.merge(billing_address_1: "")) }

        it { should_not be_billing_address_complete }
      end

      context "billing address is missing billing_postal_code" do
        subject { Factory.create(:user, full_billing_address.merge(billing_postal_code: "")) }

        it { should_not be_billing_address_complete }
      end

      context "billing address is missing billing_city" do
        subject { Factory.create(:user, full_billing_address.merge(billing_city: "")) }

        it { should_not be_billing_address_complete }
      end

      context "billing address is missing billing_country" do
        subject { Factory.create(:user, full_billing_address.merge(billing_country: "")) }

        it { should_not be_billing_address_complete }
      end
    end

    describe "#support" do
      context "user has no site" do
        before(:all) do
          @user = Factory.create(:user)
        end
        subject { @user.reload }

        it { subject.support.should eql "forum" }
      end

      context "user has only sites with forum support" do
        before(:all) do
          @user = Factory.create(:user)
          Factory.create(:site, user: @user, plan_id: @free_plan.id,)
        end
        subject { @user.reload }
        it { @free_plan.support.should eql "forum" }
        it { subject.support.should eql "forum" }
      end

      context "user has at least one site with email support" do
        before(:all) do
          @user = Factory.create(:user)
          Factory.create(:site, user: @user, plan_id: @free_plan.id, first_paid_plan_started_at: PublicLaunch.v2_started_on - 1.day)
          Factory.create(:site, user: @user, plan_id: @paid_plan.id, first_paid_plan_started_at: PublicLaunch.v2_started_on - 1.day)
        end
        subject { @user.reload }

        it { @free_plan.support.should eql "forum" }
        it { @paid_plan.support.should eql "email" }
        its(:support) { should eql "email" }
      end

      context "user has at least one site with vip support" do
        before(:all) do
          @user = Factory.create(:user)
          Factory.create(:site, user: @user, plan_id: @free_plan.id, first_paid_plan_started_at: PublicLaunch.v2_started_on - 1.day)
          Factory.create(:site, user: @user, plan_id: @paid_plan.id, first_paid_plan_started_at: PublicLaunch.v2_started_on - 1.day)
          Factory.create(:site, user: @user, plan_id: @custom_plan.token, first_paid_plan_started_at: PublicLaunch.v2_started_on - 1.day)
        end
        subject { @user.reload }

        it { @free_plan.support.should eql "forum" }
        it { @paid_plan.support.should eql "email" }
        it { @custom_plan.support.should eql "vip" }
        its(:support) { should eql "vip" }
      end
    end

    describe "#billable?" do
      before(:all) do
        Site.delete_all
        @billable_user_1 = Factory.create(:user)
        @billable_user_2 = Factory.create(:user)
        @non_billable_user_1 = Factory.create(:user)
        @non_billable_user_2 = Factory.create(:user)
        @non_billable_user_3 = Factory.create(:user)
        @non_billable_user_4 = Factory.create(:user)

        # billable
        Factory.create(:site, user: @billable_user_1, plan_id: @paid_plan.id)
        site_will_be_paid = Factory.create(:site, user: @billable_user_2, plan_id: @paid_plan.id)
        site_will_be_paid.update_attribute(:next_cycle_plan_id, Factory.create(:plan).id)

        # not billable
        Factory.create(:site, user: @non_billable_user_1, plan_id: @free_plan.id)
        site_will_be_free = Factory.create(:site, user: @non_billable_user_2, plan_id: @paid_plan.id)
        site_will_be_free.update_attribute(:next_cycle_plan_id, @free_plan.id)
        site_archived = Factory.create(:site, user: @non_billable_user_3, state: "archived", archived_at: Time.utc(2010,2,28))
        Factory.create(:site, user: @non_billable_user_4, state: "suspended")
      end

      it { @billable_user_1.should be_billable }
      it { @billable_user_2.should be_billable }
      it { @non_billable_user_1.should_not be_billable }
      it { @non_billable_user_2.should_not be_billable }
      it { @non_billable_user_3.should_not be_billable }
      it { @non_billable_user_4.should_not be_billable }
    end

    describe "#archivable?" do
      subject { @site.reload; @site.user }

      context "first invoice" do
        before(:all) do
          Invoice.delete_all
          @site = Factory.create(:new_site, first_paid_plan_started_at: nil)
          @site.first_paid_plan_started_at.should be_nil
        end

        context "with an open invoice" do
          before(:all) do
            @open_invoice = Factory.create(:invoice, site: @site, state: 'open')
          end

          it { should be_archivable }
        end

        context "with a failed invoice" do
          before(:all) do
            @failed_invoice = Factory.create(:invoice, site: @site, state: 'failed')
          end

          it { should be_archivable }
        end

        context "with a waiting invoice" do
          before(:all) do
            @waiting_invoice = Factory.create(:invoice, site: @site, state: 'waiting')
          end

          it { should_not be_archivable }
        end
      end

      context "not first invoice" do
        before(:all) do
          Invoice.delete_all
          @site = Factory.create(:new_site, first_paid_plan_started_at: Time.now.utc)
          @site.first_paid_plan_started_at.should be_present
        end

        context "with an open invoice" do
          before(:all) do
            @open_invoice = Factory.create(:invoice, site: @site, state: 'open')
          end

          it { should_not be_archivable }
        end

        context "with a failed invoice" do
          before(:all) do
            @failed_invoice = Factory.create(:invoice, site: @site, state: 'failed')
          end

          it { should_not be_archivable }
        end

        context "with a waiting invoice" do
          before(:all) do
            @waiting_invoice = Factory.create(:invoice, site: @site, state: 'waiting')
          end

          it { should_not be_archivable }
        end
      end
    end

  end

  def accept_invitation(attributes = {})
    default = {
      password: "123456",
      name: "John Doe",
      billing_country: "CH",
      billing_postal_code: "2000",
      use_company: true,
      company_name: "bob",
      company_url: "bob.com",
      terms_and_conditions: "1",
      invitation_token: @user.invitation_token
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
#  billing_postal_code    :string(255)
#  billing_country        :string(255)
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
#  balance                :integer         default(0)
#  hidden_notice_ids      :text
#  name                   :string(255)
#  billing_name           :string(255)
#  billing_address_1      :string(255)
#  billing_address_2      :string(255)
#  billing_city           :string(255)
#  billing_region         :string(255)
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

