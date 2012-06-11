# coding: utf-8
require 'spec_helper'
require 'ostruct'

describe User do

  let(:full_billing_address) do
    { billing_address_1: "EPFL Innovation Square", billing_address_2: "PSE-D",
      billing_postal_code: "1015", billing_city: "New York", billing_region: "NY",
      billing_country: "US" }
  end

  context "Factory" do
    before(:all) { @user = build(:user) }
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
    its(:newsletter)           { should be_false }
    its(:email)                { should match /email\d+@user.com/ }
    its(:hidden_notice_ids)    { should eq [] }
    its(:vip)                  { should be_false }

    it { should be_valid }
  end

  describe "Associations" do
    before(:all) { @user = create(:user) }
    subject { @user }

    it { should have_many :sites }
    it { should have_many(:invoices).through(:sites) }
    it { should have_many :deal_activations }
    it { should have_many :client_applications }
    it { should have_many :tokens }
  end

  describe "Validations" do
    [:name, :email, :postal_code, :country, :confirmation_comment, :remember_me, :password, :billing_address_1, :billing_address_2, :billing_postal_code, :billing_city, :billing_region, :billing_country, :use_personal, :use_company, :use_clients, :company_name, :company_url, :terms_and_conditions, :hidden_notice_ids, :cc_register, :cc_brand, :cc_full_name, :cc_number, :cc_expiration_month, :cc_expiration_year, :cc_verification_value].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end

    # Devise checks presence/uniqueness/format of email, presence/length of password
    it { should validate_presence_of(:email) }
    it { should ensure_length_of(:billing_postal_code).is_at_most(20) }
    it { should validate_acceptance_of(:terms_and_conditions) }

    describe "email" do
      context "email already taken by an active user" do
        it "is not valid" do
          active_user = create(:user, state: 'active', email: "john@doe.com")
          user = build(:user, email: active_user.email)
          user.should_not be_valid
          user.should have(1).error_on(:email)
        end
      end

      context "email already taken by an archived user" do
        it "is valid" do
          archived_user = create(:user, state: 'archived', email: "john@doe.com")
          user = build(:user, email: archived_user.email)
          user.should be_valid
        end
      end
    end

    describe "company_url" do
      context "is present" do
        it "is not valid" do
          user = build(:user, use_company: true, company_url: "http://localhost")
          user.should_not be_valid
          user.should have(1).error_on(:company_url)
        end
      end

      context "is not present" do
        it "is valid" do
          user = build(:user, use_company: true, company_url: "")
          user.should be_valid
        end
      end
    end

    context "when update email" do
      it "should validate current_password presence" do
        user = create(:user)
        user.update_attributes(email: "bob@doe.com").should be_false
        user.errors[:current_password].should eq ["can't be blank"]
      end

      it "should validate current_password" do
        user = create(:user)
        user.update_attributes(email: "bob@doe.com", current_password: "wrong").should be_false
        user.errors[:current_password].should eq ["is invalid"]
      end

      it "should not validate current_password with other errors" do
        user = create(:user)
        user.update_attributes(password: "newone", email: 'wrong').should be_false
        user.errors[:current_password].should be_empty
      end
    end

    context "when update password" do
      it "should validate current_password presence" do
        user = create(:user)
        user.update_attributes(password: "newone").should be_false
        user.errors[:current_password].should eq ["can't be blank"]
      end

      it "should validate current_password" do
        user = create(:user)
        user.update_attributes(password: "newone", current_password: "wrong").should be_false
        user.errors[:current_password].should eq ["is invalid"]
      end

      it "should not validate current_password with other errors" do
        user = create(:user)
        user.update_attributes(password: "newone", email: '').should be_false
        user.errors[:current_password].should be_empty
      end
    end

    context "when archive" do
      it "should validate current_password presence" do
        user = create(:user)
        user.archive.should be_false
        user.errors[:current_password].should eq ["can't be blank"]
      end

      it "should validate current_password" do
        user = create(:user)
        user.current_password = 'wrong'
        user.archive.should be_false
        user.errors[:current_password].should eq ["is invalid"]
      end

      describe "prevent_archive_with_non_paid_invoices" do
        subject { @site.user }
        before { Invoice.delete_all }

        context "first invoice" do
          before do
            @site = create(:new_site, first_paid_plan_started_at: nil)
            @site.first_paid_plan_started_at.should be_nil
            @site.user.current_password = '123456'
          end

          %w[open failed].each do |invoice_state|
            context "with an #{invoice_state} invoice" do
              before { create(:invoice, site: @site, state: invoice_state) }

              it "archives the user" do
                subject.archive.should be_true
                subject.errors[:base].should be_empty
              end
            end
          end

          context "with a waiting invoice" do
            before { create(:invoice, site: @site, state: 'waiting') }

            it "archives the user" do
              subject.archive.should be_false
              subject.errors[:base].should include I18n.t('activerecord.errors.models.user.attributes.base.not_paid_invoices_prevent_archive', count: 1)
            end
          end
        end

        context "not first invoice" do
          before do
            @site = create(:new_site, first_paid_plan_started_at: Time.now.utc)
            @site.first_paid_plan_started_at.should be_present
            @site.user.current_password = '123456'
          end

          %w[open waiting failed].each do |invoice_state|
            context "with an #{invoice_state} invoice" do
              before { create(:invoice, site: @site, state: invoice_state) }

              it "doesn't archive the user" do
                subject.archive.should be_false
                subject.errors[:base].should include I18n.t('activerecord.errors.models.user.attributes.base.not_paid_invoices_prevent_archive', count: 1)
              end
            end
          end
        end
      end

    end
  end

  context "invited" do
    subject { create(:user).tap { |u| u.assign_attributes({ invitation_token: '123', invitation_sent_at: Time.now, email: "bob@bob.com", enthusiast_id: 12 }, without_protection: true); u.save(validate: false) } }

    it "should not be able to update enthusiast_id" do
      lambda { subject.update_attributes(enthusiast_id: 13) }.should raise_error
    end
  end

  describe "State Machine" do
    before do
      @user           = create(:user)
      @free_site      = create(:site, user: @user, plan_id: @free_plan.id, hostname: "octavez.com")
      @paid_site      = create(:site, user: @user, hostname: "rymai.com")
      @suspended_site = create(:site, user: @user, hostname: "rymai.me", state: 'suspended')
      create(:invoice, site: @paid_site, state: 'failed')
    end

    describe "Initial State" do
      subject { @user }
      it { should be_active }
    end

    describe "#suspend" do
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
            @archived_site  = create(:site, user: @user, hostname: "rymai.tv", state: 'archived')
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
      before { @user.reload.update_attribute(:state, 'suspended') }
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
        before do
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
        before do
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
          @site = create(:new_site, first_paid_plan_started_at: nil)
          Invoice.delete_all
          @site.first_paid_plan_started_at.should be_nil
        end

        context "with an open invoice" do
          it "archives the user" do
            @open_invoice = create(:invoice, site: @site, state: 'open')
            subject.archive!.should be_true
            subject.should be_archived
            @open_invoice.reload.should be_canceled
          end
        end

        context "with a failed invoice" do
          it "archives the user" do
            @failed_invoice = create(:invoice, site: @site, state: 'failed')
            subject.archive!.should be_true
            subject.should be_archived
            @failed_invoice.reload.should be_canceled
          end
        end

        context "with a waiting invoice" do
          it "archives the user" do
            @waiting_invoice = create(:invoice, site: @site, state: 'waiting')
            subject.archive.should be_false
            subject.should_not be_archived
            @waiting_invoice.reload.should be_waiting
          end
        end
      end

      context "not first invoice" do
        subject { @site.user }
        before do
          @site = create(:new_site, first_paid_plan_started_at: Time.now.utc)
          @site.user.current_password = '123456'
          @site.first_paid_plan_started_at.should be_present
          Invoice.delete_all
        end

        %w[open waiting failed].each do |invoice_state|
          context "with an #{invoice_state} invoice" do
            before { create(:invoice, site: @site, state: invoice_state) }

            it "doesn't archive the user" do
              subject.archive.should be_false
              subject.errors[:base].should include I18n.t('activerecord.errors.models.user.attributes.base.not_paid_invoices_prevent_archive', count: 1)
            end
          end
        end
      end

      describe "Callbacks" do
        before do
          Invoice.delete_all
        end
        subject { @user.reload }

        describe "before_transition on: :archive, do: [:set_archived_at, :invalidate_tokens, :archive_sites]" do
          it "sets archived_at" do
            subject.archived_at.should be_nil
            subject.current_password = "123456"
            subject.archive
            subject.archived_at.should be_present
          end

          it "invalidates all user's tokens" do
            create(:oauth2_token, user: subject)
            subject.reload.tokens.first.should_not be_invalidated_at
            subject.current_password = "123456"
            subject.archive
            subject.reload.tokens.all? { |token| token.invalidated_at? }.should be_true
          end

          it "archives each user' site" do
            subject.sites.all? { |site| site.should_not be_archived }
            subject.current_password = "123456"
            subject.archive
            subject.sites.all? { |site| site.reload.should be_archived }
          end
        end

        describe "after_transition on: :archive, do: [:newsletter_unsubscribe, :send_account_archived_email]" do
          it "sends an email to user" do
            subject.current_password = "123456"
            expect { subject.archive }.to change(ActionMailer::Base.deliveries, :count).by(1)
            ActionMailer::Base.deliveries.last.to.should eq [subject.email]
          end

          describe ":newsletter_unsubscribe" do
            subject { create(:user, newsletter: "1", email: "john@doe.com") }
            before do
              VoxcastCDN.stub(:purge)
              PusherWrapper.stub(:trigger)
            end

            it "subscribes new email and unsubscribe old email on user destroy" do
              subject.current_password = "123456"

              NewsletterManager.should_receive(:unsubscribe).with(subject)
              subject.archive!
            end
          end
        end

      end
    end

  end

  describe "Callbacks" do

    describe "before_save :prepare_pending_credit_card & after_save :register_credit_card_on_file" do

      context "when user had no cc info before" do
        use_vcr_cassette "ogone/void_authorization"
        subject do
          user = create(:user_no_cc)
          user.reload
          user.update_attributes(valid_cc_attributes)
          user
        end

        it { should be_valid }
        its(:cc_type)        { should eq 'visa' }
        its(:cc_last_digits) { should eq '1111' }
        its(:cc_expire_on)   { should eq 1.year.from_now.end_of_month.to_date }

        its(:pending_cc_type)        { should be_nil }
        its(:pending_cc_last_digits) { should be_nil }
        its(:pending_cc_expire_on)   { should be_nil }
      end

      context "when user has cc info before" do
        subject { create(:user) }
        before do
          subject.cc_type.should eq 'visa'
          subject.cc_last_digits.should eq '1111'
          subject.cc_expire_on.should eq 1.year.from_now.end_of_month.to_date

          subject.attributes = valid_cc_attributes_master
          VCR.use_cassette("ogone/void_authorization") { subject.save! }
          subject.reload
        end

        it { should be_valid }
        its(:cc_type)        { should eq 'master' }
        its(:cc_last_digits) { should eq '9999' }
        its(:cc_expire_on)   { should eq 2.years.from_now.end_of_month.to_date }

        its(:pending_cc_type)        { should be_nil }
        its(:pending_cc_last_digits) { should be_nil }
        its(:pending_cc_expire_on)   { should be_nil }
      end
    end

    describe "after_create :delay_send_welcome_email" do
      subject { create(:user) }

      it "delays send_welcome_email" do
        expect { subject }.to change(Delayed::Job.where { handler =~ "%Class%send_welcome_email%" }, :count).by(1)
      end

      it "send the welcome email" do
        subject
        expect { @worker.work_off }.to change(ActionMailer::Base.deliveries, :count).by(1)
      end
    end

    describe "after_create :sync_newsletter" do
      subject { create(:user, newsletter: false) }

      it "calls NewsletterManager.sync_newsletter" do
        NewsletterManager.should_receive(:sync_from_service)
        subject
      end
    end

    describe "after_save :newsletter_update" do
      context "user sign-up" do
        context "user subscribes to the newsletter" do
          subject { create(:user, newsletter: true, email: "newsletter_sign_up@jilion.com") }

          it 'calls NewsletterManager.subscribe' do
            NewsletterManager.should_receive(:subscribe)
            subject
          end
        end

        context "user doesn't subscribe to the newsletter" do
          subject { create(:user, newsletter: false, email: "no_newsletter_sign_up@jilion.com") }

          it "doesn't calls NewsletterManager.subscribe" do
            NewsletterManager.should_not_receive(:subscribe)
            subject
          end
        end
      end

      context "user update" do
        subject { create(:user, newsletter: true, email: "newsletter_update@jilion.com") }

        it "registers user's new email on Campaign Monitor and remove old email when user update his email" do
          subject
          expect {
            subject.update_attribute(:email, "newsletter_update2@jilion.com")
            subject.confirm!
          }.to change(Delayed::Job, :count).by(1)
          Delayed::Job.last.name.should eq "Class#update"
        end

        it "updates info in Campaign Monitor if user change his name" do
          subject
          expect { subject.update_attribute(:name, "bob") }.to change(Delayed::Job, :count).by(1)
          Delayed::Job.last.name.should eq "Class#update"
        end

        it "updates subscribing state in Campaign Monitor if user change his newsletter state" do
          subject
          expect { subject.update_attribute(:newsletter, false) }.to change(Delayed::Job, :count).by(1)
          djs = Delayed::Job.last.name.should eq "Class#unsubscribe"
        end
      end
    end

    describe "after_update :zendesk_update" do
      subject { create(:user) }
      before do
        NewsletterManager.stub(:sync_from_service)
      end

      context "user has no zendesk_id" do
        it "doesn't delay ZendeskWrapper.update_user" do
          subject
          expect {
            subject.update_attribute(:email, "new@jilion.com")
          }.to_not change(Delayed::Job, :count)
        end
      end

      context "user has a zendesk_id" do
        before { subject.update_attribute(:zendesk_id, 59438671) }

        context "user updated his email" do
          it "delays ZendeskWrapper.update_user if the user has a zendesk_id and his email has changed" do
            expect {
              subject.update_attribute(:email, "new@jilion.com")
              subject.confirm!
            }.to change(Delayed::Job.where { handler =~ '%Module%update_user%' }, :count).by(1)
          end

          it "updates user's email on Zendesk if this user has a zendesk_id and his email has changed" do
            subject.update_attribute(:email, "new@jilion.com")
            subject.confirm!

            VCR.use_cassette("user/zendesk_update") do
              @worker.work_off
              Delayed::Job.last.should be_nil
              ZendeskWrapper.send(:client).users(59438671).identities.first.value.should eq 'new@jilion.com'
            end
          end
        end

        context "user updated his name" do
          it "delays ZendeskWrapper.update_user" do
            expect { subject.update_attribute(:name, "Remy") }.to change(Delayed::Job.where { handler =~ '%Module%update_user%' }, :count).by(1)
          end

          it "updates user's name on Zendesk" do
            subject.update_attribute(:name, "Remy")

            VCR.use_cassette("user/zendesk_update") do
              @worker.work_off
              Delayed::Job.last.should be_nil
              ZendeskWrapper.user(59438671).name.should eq 'Remy'
            end
          end

          context "name has changed to ''" do
            it "doesn't update user's name on Zendesk" do
              expect { subject.update_attribute(:name, '') }.to_not change(Delayed::Job, :count)
            end
          end
        end
      end
    end

  end

  describe "attributes accessor" do
    subject { create(:user, email: "BoB@CooL.com") }

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
    subject { create(:user) }

    describe "#notice_hidden?" do
      before do
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
        subject { create(:user, created_at: Time.utc(2010,10,10), invitation_token: nil) }

        its(:beta?) { should be_true }
      end
      context "with un active beta user" do
        subject { create(:user, created_at: Time.utc(2010,10,10), invitation_token: 'xxx') }

        its(:beta?) { should be_false }
      end
      context "with a standard user (limit)" do
        subject { create(:user, created_at: Time.utc(2011,3,29).midnight, invitation_token: nil) }

        its(:beta?) { should be_false }
      end
      context "with a standard user" do
        subject { create(:user, created_at: Time.utc(2011,3,30), invitation_token: nil) }

        its(:beta?) { should be_false }
      end
    end

    describe "#vat?" do
      context "with Swiss user" do
        subject { create(:user, billing_country: 'CH') }

        its(:vat?) { should be_true }
      end

      context "with USA user" do
        subject { create(:user, billing_country: 'US') }

        its(:vat?) { should be_false }
      end
    end

    describe "#name_or_email" do
      context "user has no name" do
        subject { create(:user, name: nil, email: "john@doe.com") }
        its(:name_or_email) { should eq "john@doe.com" }
      end

      context "user has a name" do
        subject { create(:user, name: "John Doe", email: "john@doe.com") }
        its(:name_or_email) { should eq "John Doe" }
      end
    end

    describe "#billing_address" do
      context "delegates to snail using billing info" do
        subject { create(:user, full_billing_address) }

        its(:billing_address) { should eq "Remy Coutable\nEPFL Innovation Square\nPSE-D\nNew York NY  1015\nUNITED STATES" }
      end

      context "billing_name is missing" do
        subject { create(:user, full_billing_address.merge(billing_name: "")) }

        its(:billing_address) { should eq "John Doe\nEPFL Innovation Square\nPSE-D\nNew York NY  1015\nUNITED STATES" }
      end

      context "billing_postal_code is missing" do
        subject { create(:user, full_billing_address.merge(billing_postal_code: "")) }

        its(:billing_address) { should eq "Remy Coutable\nEPFL Innovation Square\nPSE-D\nNew York NY  \nUNITED STATES" }
      end

      context "billing_country is missing" do
        subject { create(:user, full_billing_address.merge(billing_country: "")) }

        its(:billing_address) { should eq "Remy Coutable\nEPFL Innovation Square\nPSE-D\nNew York NY  1015" }
      end
    end

    describe "#billing_address_complete?" do
      context "complete billing address" do
        subject { create(:user, full_billing_address) }

        it { should be_billing_address_complete }
      end

      context "billing address is missing billing_address_2" do
        subject { create(:user, full_billing_address.merge(billing_address_2: "")) }

        it { should be_billing_address_complete }
      end

      context "billing address is missing billing_region" do
        subject { create(:user, full_billing_address.merge(billing_region: "")) }

        it { should be_billing_address_complete }
      end

      context "billing address is missing billing_address_1" do
        subject { create(:user, full_billing_address.merge(billing_address_1: "")) }

        it { should_not be_billing_address_complete }
      end

      context "billing address is missing billing_postal_code" do
        subject { create(:user, full_billing_address.merge(billing_postal_code: "")) }

        it { should_not be_billing_address_complete }
      end

      context "billing address is missing billing_city" do
        subject { create(:user, full_billing_address.merge(billing_city: "")) }

        it { should_not be_billing_address_complete }
      end

      context "billing address is missing billing_country" do
        subject { create(:user, full_billing_address.merge(billing_country: "")) }

        it { should_not be_billing_address_complete }
      end
    end

    describe "#more_info_incomplete?" do
      context "more info complete" do
        subject { create(:user, company_name: 'Jilion', company_url: 'http://jilion.com', company_job_title: 'Foo', company_employees: 'foo') }

        it { should_not be_more_info_incomplete }
      end

      context "company_name is missing" do
        subject { create(:user, company_name: '', company_url: 'http://jilion.com', company_job_title: 'Foo', company_employees: 'foo') }

        it { should be_more_info_incomplete }
      end

      context "company_url is missing" do
        subject { create(:user, company_name: 'Jilion', company_url: '', company_job_title: 'Foo', company_employees: 'foo') }

        it { should be_more_info_incomplete }
      end

      context "company_job_title is missing" do
        subject { create(:user, company_name: 'Jilion', company_url: 'http://jilion.com', company_job_title: '', company_employees: 'foo') }

        it { should be_more_info_incomplete }
      end

      context "company_employees is missing" do
        subject { create(:user, company_name: 'Jilion', company_url: 'http://jilion.com', company_job_title: 'Foo', company_employees: '') }

        it { should be_more_info_incomplete }
      end

      context "use is missing" do
        subject { create(:user, company_name: 'Jilion', company_url: 'http://jilion.com', company_job_title: 'Foo', company_employees: 'foo', use_personal: nil) }

        it { should be_more_info_incomplete }
      end
    end

    describe "#activated_deals" do
      subject { create(:user) }

      context "without deals activated" do
        its(:activated_deals) { should be_empty }
      end

      context "with deals activated" do
        let(:deal1) { create(:deal, value: 0.3, started_at: 2.days.ago, ended_at: 2.days.from_now) }
        let(:deal2) { create(:deal, value: 0.4, started_at: 1.days.ago, ended_at: 3.days.from_now) }
        before do
          @deal_activation1 = create(:deal_activation, deal: deal1, user: subject)
          @deal_activation2 = create(:deal_activation, deal: deal2, user: subject)
        end

        its(:activated_deals) { should eq [deal2, deal1] }
      end
    end

    describe "#latest_activated_deal" do
      subject { create(:user) }

      context "without deals activated" do
        its(:latest_activated_deal) { should be_nil }
      end

      context "with deals activated" do
        let(:deal1) { create(:deal, value: 0.3, started_at: 2.days.ago, ended_at: 2.days.from_now) }
        let(:deal2) { create(:deal, value: 0.4, started_at: 1.days.ago, ended_at: 3.days.from_now) }
        before do
          @deal_activation1 = create(:deal_activation, deal: deal1, user: subject)
          @deal_activation2 = create(:deal_activation, deal: deal2, user: subject)
        end

        its(:latest_activated_deal) { should eq deal2 }

        it "returns a deal even if it not active anymore" do
          Timecop.travel(4.days.from_now) do
            subject.latest_activated_deal.should eq deal2
          end
        end
      end
    end

    describe "#latest_activated_deal_still_active" do
      subject { create(:user) }

      context "without deals activated" do
        its(:latest_activated_deal_still_active) { should be_nil }
      end

      context "with deals activated" do
        let(:deal1) { create(:deal, value: 0.3, started_at: 2.days.ago, ended_at: 2.days.from_now) }
        let(:deal2) { create(:deal, value: 0.4, started_at: 1.days.ago, ended_at: 3.days.from_now) }
        before do
          @deal_activation1 = create(:deal_activation, deal: deal1, user: subject)
          @deal_activation2 = create(:deal_activation, deal: deal2, user: subject)
        end

        it "returns only a deal that is still active" do
          Timecop.travel(4.days.from_now) do
            subject.latest_activated_deal_still_active.should be_nil
          end
        end
      end
    end

    describe "#support & #email_support?" do
      context "user has no site" do
        before(:all) do
          @user = create(:user)
        end
        subject { @user.reload }

        it { subject.support.should eq "forum" }
      end

      context "user has only sites with forum support" do
        before(:all) do
          @user = create(:user)
          create(:site, user: @user, plan_id: @free_plan.id,)
        end
        subject { @user.reload }
        it { @free_plan.support.should eq "forum" }
        its(:support) { should eq "forum" }
        its(:email_support?) { should be_false }
      end

      context "user has at least one site with email support" do
        before(:all) do
          @user = create(:user)
          create(:site, user: @user, plan_id: @free_plan.id, first_paid_plan_started_at: PublicLaunch.v2_started_on - 1.day)
          create(:site, user: @user, plan_id: @paid_plan.id, first_paid_plan_started_at: PublicLaunch.v2_started_on - 1.day)
        end
        subject { @user.reload }

        it { @free_plan.support.should eq "forum" }
        it { @paid_plan.support.should eq "email" }
        its(:support) { should eq "email" }
        its(:email_support?) { should be_true }
      end

      context "user has at least one site with vip email support" do
        before(:all) do
          @user = create(:user)
          create(:site, user: @user, plan_id: @free_plan.id, first_paid_plan_started_at: PublicLaunch.v2_started_on - 1.day)
          create(:site, user: @user, plan_id: @paid_plan.id, first_paid_plan_started_at: PublicLaunch.v2_started_on - 1.day)
          create(:site, user: @user, plan_id: @custom_plan.token, first_paid_plan_started_at: PublicLaunch.v2_started_on - 1.day)
        end
        subject { @user.reload }

        it { @free_plan.support.should eq "forum" }
        it { @paid_plan.support.should eq "email" }
        it { @custom_plan.support.should eq "vip_email" }
        its(:support) { should eq "vip_email" }
        its(:email_support?) { should be_true }
      end
    end

    describe "#billable?" do
      before(:all) do
        Site.delete_all
        @billable_user_1 = create(:user)
        @billable_user_2 = create(:user)
        @billable_user_3 = create(:user)
        @non_billable_user_1 = create(:user)
        @non_billable_user_2 = create(:user)
        @non_billable_user_3 = create(:user)

        # billable
        create(:site, user: @billable_user_1, plan_id: @paid_plan.id)
        site_will_be_paid = create(:site, user: @billable_user_2, plan_id: @paid_plan.id)
        site_will_be_paid.update_attribute(:next_cycle_plan_id, create(:plan).id)
        site_will_be_free = create(:site, user: @billable_user_3, plan_id: @paid_plan.id)
        site_will_be_free.update_attribute(:next_cycle_plan_id, @free_plan.id)

        # not billable
        create(:site, user: @non_billable_user_1, plan_id: @free_plan.id)
        site_archived = create(:site, user: @non_billable_user_2, state: "archived", archived_at: Time.utc(2010,2,28))
        create(:site, user: @non_billable_user_3, state: "suspended")
      end

      it { @billable_user_1.should be_billable }
      it { @billable_user_2.should be_billable }
      it { @non_billable_user_1.should_not be_billable }
      it { @non_billable_user_2.should_not be_billable }
      it { @non_billable_user_3.should_not be_billable }
    end

    describe "#archivable?" do
      subject { @site.reload; @site.user }

      context "first invoice" do
        before(:all) do
          Invoice.delete_all
          @site = create(:new_site, first_paid_plan_started_at: nil)
          @site.first_paid_plan_started_at.should be_nil
        end

        context "with an open invoice" do
          before do
            @open_invoice = create(:invoice, site: @site, state: 'open')
          end

          it { should be_archivable }
        end

        context "with a failed invoice" do
          before do
            @failed_invoice = create(:invoice, site: @site, state: 'failed')
          end

          it { should be_archivable }
        end

        context "with a waiting invoice" do
          before do
            @waiting_invoice = create(:invoice, site: @site, state: 'waiting')
          end

          it { should_not be_archivable }
        end
      end

      context "not first invoice" do
        before(:all) do
          Invoice.delete_all
          @site = create(:new_site, first_paid_plan_started_at: Time.now.utc)
          @site.first_paid_plan_started_at.should be_present
        end

        context "with an open invoice" do
          before do
            @open_invoice = create(:invoice, site: @site, state: 'open')
          end

          it { should_not be_archivable }
        end

        context "with a failed invoice" do
          before do
            @failed_invoice = create(:invoice, site: @site, state: 'failed')
          end

          it { should_not be_archivable }
        end

        context "with a waiting invoice" do
          before do
            @waiting_invoice = create(:invoice, site: @site, state: 'waiting')
          end

          it { should_not be_archivable }
        end
      end
    end

    describe '#create_zendesk_user' do
      context 'user has a zendesk id' do
        subject { build(:user, zendesk_id: 42) }

        it 'does nothing' do
          ZendeskWrapper.should_not_receive(:create_user)
          subject.should_not_receive(:update_attribute)
          subject.create_zendesk_user
        end
      end

      context 'user has no zendesk id' do
        subject { build(:user) }

        it 'create a user in Zendesk and set the zendesk_id from it' do
          ZendeskWrapper.should_receive(:create_user).with(subject).and_return(OpenStruct.new(id: 42))
          subject.should_receive(:update_attribute).with(:zendesk_id, 42)
          subject.create_zendesk_user
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
#  id                              :integer         not null, primary key
#  state                           :string(255)
#  email                           :string(255)     default(""), not null
#  encrypted_password              :string(128)     default(""), not null
#  password_salt                   :string(255)     default(""), not null
#  confirmation_token              :string(255)
#  confirmed_at                    :datetime
#  confirmation_sent_at            :datetime
#  reset_password_token            :string(255)
#  remember_token                  :string(255)
#  remember_created_at             :datetime
#  sign_in_count                   :integer         default(0)
#  current_sign_in_at              :datetime
#  last_sign_in_at                 :datetime
#  current_sign_in_ip              :string(255)
#  last_sign_in_ip                 :string(255)
#  failed_attempts                 :integer         default(0)
#  locked_at                       :datetime
#  cc_type                         :string(255)
#  cc_last_digits                  :string(255)
#  cc_expire_on                    :date
#  cc_updated_at                   :datetime
#  created_at                      :datetime
#  updated_at                      :datetime
#  invitation_token                :string(60)
#  invitation_sent_at              :datetime
#  zendesk_id                      :integer
#  enthusiast_id                   :integer
#  postal_code                     :string(255)
#  country                         :string(255)
#  use_personal                    :boolean
#  use_company                     :boolean
#  use_clients                     :boolean
#  company_name                    :string(255)
#  company_url                     :string(255)
#  company_job_title               :string(255)
#  company_employees               :string(255)
#  company_videos_served           :string(255)
#  cc_alias                        :string(255)
#  pending_cc_type                 :string(255)
#  pending_cc_last_digits          :string(255)
#  pending_cc_expire_on            :date
#  pending_cc_updated_at           :datetime
#  archived_at                     :datetime
#  newsletter                      :boolean         default(FALSE)
#  last_invoiced_amount            :integer         default(0)
#  total_invoiced_amount           :integer         default(0)
#  balance                         :integer         default(0)
#  hidden_notice_ids               :text
#  name                            :string(255)
#  billing_name                    :string(255)
#  billing_address_1               :string(255)
#  billing_address_2               :string(255)
#  billing_postal_code             :string(255)
#  billing_city                    :string(255)
#  billing_region                  :string(255)
#  billing_country                 :string(255)
#  last_failed_cc_authorize_at     :datetime
#  last_failed_cc_authorize_status :integer
#  last_failed_cc_authorize_error  :string(255)
#  referrer_site_token             :string(255)
#  reset_password_sent_at          :datetime
#  confirmation_comment            :text
#  unconfirmed_email               :string(255)
#  invitation_accepted_at          :datetime
#  invitation_limit                :integer
#  invited_by_id                   :integer
#  invited_by_type                 :string(255)
#  vip                             :boolean         default(FALSE)
#
# Indexes
#
#  index_users_on_cc_alias               (cc_alias) UNIQUE
#  index_users_on_confirmation_token     (confirmation_token) UNIQUE
#  index_users_on_created_at             (created_at)
#  index_users_on_current_sign_in_at     (current_sign_in_at)
#  index_users_on_email_and_archived_at  (email,archived_at) UNIQUE
#  index_users_on_last_invoiced_amount   (last_invoiced_amount)
#  index_users_on_referrer_site_token    (referrer_site_token)
#  index_users_on_reset_password_token   (reset_password_token) UNIQUE
#  index_users_on_total_invoiced_amount  (total_invoiced_amount)
#

