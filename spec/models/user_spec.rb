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
    subject { build(:user) }

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
    subject { create(:user) }

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

    end
  end

  context "invited" do
    subject { create(:user).tap { |u| u.assign_attributes({ invitation_token: '123', invitation_sent_at: Time.now, email: "bob@bob.com", enthusiast_id: 12 }, without_protection: true); u.save(validate: false) } }

    it "should not be able to update enthusiast_id" do
      expect { subject.update_attributes(enthusiast_id: 13) }.to raise_error
    end
  end

  describe "State Machine" do
    let(:user)           { create(:user) }
    let(:paid_site)      { create(:site, user: user, hostname: "rymai.com") }
    let(:suspended_site) { create(:site, user: user, hostname: "rymai.me", state: 'suspended') }
    let(:archived_site)  { create(:site, user: user, hostname: "rymai.tv", state: 'archived') }
    subject { user }

    describe "Initial State" do
      it { should be_active }
    end

    describe "#suspend" do
      context "from active state" do
        before do
          user.suspend
        end

        it { should be_suspended }
      end

      describe "Callbacks" do
        describe "before_transition on: :suspend, do: :suspend_sites" do
          before do
            create(:invoice, site: paid_site, state: 'failed')
          end

          it "should suspend all user' active sites that have failed invoices" do
            paid_site.should be_active
            archived_site.should be_archived

            user.suspend

            paid_site.reload.should be_suspended
            archived_site.reload.should be_archived
          end
        end

        describe "after_transition  on: :suspend, do: :send_account_suspended_email" do
          it "should send an email to the user" do
            -> { user.suspend }.should delay('%Class%account_suspended%')
          end
        end
      end
    end

    describe "#unsuspend" do
      before { user.update_attribute(:state, 'suspended') }

      context "from suspended state" do
        it "should set the user to active" do
          user.reload.should be_suspended

          user.unsuspend

          user.should be_active
        end
      end

      describe "Callbacks" do
        describe "before_transition on: :unsuspend, do: :unsuspend_sites" do
          it "should suspend all user' sites that are suspended" do
            suspended_site.should be_suspended

            user.unsuspend

            suspended_site.reload.should be_active
          end
        end

        describe "after_transition  on: :unsuspend, do: :send_account_unsuspended_email" do
          it "should send an email to the user" do
            -> { user.unsuspend }.should delay('%Class%account_unsuspended%')
          end
        end
      end
    end

    describe "#archive" do
      [:active, :suspended].each do |state|
        context "from #{state} state" do
          before do
            user.update_attribute(:state, state)
          end

          it "requires current_password" do
            user.state.should eq state
            user.current_password = nil

            expect { user.archive! }.to raise_error(StateMachine::InvalidTransition)
          end

          it "sets the user to archived" do
            user.state.should eq state
            user.current_password = "123456"

            user.archive!

            user.should be_archived
          end
        end
      end

      describe "Callbacks" do
        before do
          Invoice.delete_all
          user.current_password = "123456"
        end

        describe "before_transition on: :archive, do: [:set_archived_at, :invalidate_tokens, :archive_sites]" do
          it "sets archived_at" do
            user.archived_at.should be_nil

            user.archive!

            user.archived_at.should be_present
          end

          it "invalidates all user's tokens" do
            create(:oauth2_token, user: user)
            user.reload.tokens.first.should_not be_invalidated_at

            user.archive!

            user.reload.tokens.all? { |token| token.invalidated_at? }.should be_true
          end

          it "archives each user' site" do
            user.sites.all? { |site| site.should_not be_archived }

            user.archive!

            user.sites.all? { |site| site.reload.should be_archived }
          end
        end

        describe "after_transition on: :archive, do: [:newsletter_unsubscribe, :send_account_archived_email]" do
          it "sends an email to user" do
            -> { user.archive }.should delay('%Class%account_archived%')
          end

          describe ":newsletter_unsubscribe" do
            let(:user) { create(:user, newsletter: "1", email: "john@doe.com") }
            before do
              CDN.stub(:purge)
              PusherWrapper.stub(:trigger)
            end

            it "subscribes new email and unsubscribe old email on user destroy" do
              NewsletterManager.should_receive(:unsubscribe).with(user)

              user.archive!
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

    describe "after_create :send_welcome_email" do
      let(:user) { create(:user) }

      it "delays UserMailer.welcome" do
        -> { user }.should delay('%Class%welcome%')
      end
    end

    describe "after_create :sync_newsletter" do
      let(:user) { create(:user, newsletter: false) }

      it "calls NewsletterManager.sync_newsletter" do
        NewsletterManager.should_receive(:sync_from_service)
        user
      end
    end

    describe "after_save :newsletter_update" do
      context "user sign-up" do
        context "user subscribes to the newsletter" do
          let(:user) { create(:user, newsletter: true, email: "newsletter_sign_up@jilion.com") }

          it 'calls NewsletterManager.subscribe' do
            NewsletterManager.should_receive(:subscribe)
            user
          end
        end

        context "user doesn't subscribe to the newsletter" do
          let(:user) { create(:user, newsletter: false, email: "no_newsletter_sign_up@jilion.com") }

          it "doesn't calls NewsletterManager.subscribe" do
            NewsletterManager.should_not_receive(:subscribe)
            user
          end
        end
      end

      context "user update" do
        let(:user) { create(:user, newsletter: true, email: "newsletter_update@jilion.com") }

        it "registers user's new email on Campaign Monitor and remove old email when user update his email" do
          user
          -> { user.update_attribute(:email, "newsletter_update2@jilion.com")
               user.confirm! }.should delay('%CampaignMonitorWrapper%update%')
        end

        it "updates info in Campaign Monitor if user change his name" do
          user
          -> { user.update_attribute(:name, 'bob') }.should delay('%CampaignMonitorWrapper%update%')
        end

        it "updates subscribing state in Campaign Monitor if user change his newsletter state" do
          user
          -> { user.update_attribute(:newsletter, false) }.should delay('%CampaignMonitorWrapper%unsubscribe%')
        end
      end
    end

    describe "after_update :zendesk_update" do
      let(:user) { create(:user) }
      before do
        NewsletterManager.stub(:sync_from_service)
      end

      context "user has no zendesk_id" do
        it "doesn't delay ZendeskWrapper.update_user" do
          user
          -> { user.update_attribute(:email, '9876@example.org') }.should_not delay
        end
      end

      context "user has a zendesk_id" do
        before { user.update_attribute(:zendesk_id, 59438671) }

        context "user updated his email" do
          it "delays ZendeskWrapper.update_user if the user has a zendesk_id and his email has changed" do
            -> { user.update_attribute(:email, "9876@example.org")
                 user.confirm! }.should delay('%Module%update_user%')
          end

          it "updates user's email on Zendesk if this user has a zendesk_id and his email has changed" do
            user.update_attribute(:email, "9876@example.org")
            user.confirm!

            VCR.use_cassette("user/zendesk_update") do
              $worker.work_off
              Delayed::Job.last.should be_nil
              ZendeskWrapper.user(59438671).identities.first.value.should eq '9876@example.org'
            end
          end
        end

        context "user updated his name" do
          it "delays ZendeskWrapper.update_user" do
            -> { user.update_attribute(:name, 'Remy') }.should delay('%Module%update_user%')
          end

          it "updates user's name on Zendesk" do
            user.update_attribute(:name, 'Remy')

            VCR.use_cassette("user/zendesk_update") do
              $worker.work_off
              Delayed::Job.last.should be_nil
              ZendeskWrapper.user(59438671).name.should eq 'Remy'
            end
          end

          context "name has changed to ''" do
            it "doesn't update user's name on Zendesk" do
              -> { user.update_attribute(:name, '') }.should_not delay
            end
          end
        end
      end
    end

  end

  describe "attributes accessor" do
    let(:user) { create(:user, email: "BoB@CooL.com") }

    describe "email=" do
      it "downcases email" do
        user.email.should eq "bob@cool.com"
      end
    end

    describe "hidden_notice_ids" do
      it "initialize as an array if nil" do
        user.hidden_notice_ids.should eq []
      end

      it "doesn't cast given value" do
        user.hidden_notice_ids << 1 << "foo"
        user.hidden_notice_ids.should eq [1, "foo"]
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

    describe "#billable?" do
      before do
        @billable_user = create(:user).tap { |user| @billable_site = create(:site, user: user) }
        @non_billable_user1 = create(:user).tap { |user| @non_billable_site1 = create(:site, user: user) }
        @non_billable_user2 = create(:user).tap { |user| @non_billable_site2 = create(:site, user: user) }

        create(:subscribed_addonship, site: @billable_site)
        create(:inactive_addonship, site: @non_billable_site1)
        create(:beta_addonship, site: @non_billable_site1)
        create(:trial_addonship, site: @non_billable_site1)
        create(:suspended_addonship, site: @non_billable_site1)
        create(:sponsored_addonship, site: @non_billable_site1)
        create(:subscribed_addonship, site: @non_billable_site2, addon: create(:addon, price: 0))
      end

      it { @billable_user.should be_billable }
      it { @non_billable_user1.should_not be_billable }
      it { @non_billable_user2.should_not be_billable }
    end

  end

end

# == Schema Information
#
# Table name: users
#
#  archived_at                     :datetime
#  balance                         :integer          default(0)
#  billing_address_1               :string(255)
#  billing_address_2               :string(255)
#  billing_city                    :string(255)
#  billing_country                 :string(255)
#  billing_name                    :string(255)
#  billing_postal_code             :string(255)
#  billing_region                  :string(255)
#  cc_alias                        :string(255)
#  cc_expire_on                    :date
#  cc_last_digits                  :string(255)
#  cc_type                         :string(255)
#  cc_updated_at                   :datetime
#  company_employees               :string(255)
#  company_job_title               :string(255)
#  company_name                    :string(255)
#  company_url                     :string(255)
#  company_videos_served           :string(255)
#  confirmation_comment            :text
#  confirmation_sent_at            :datetime
#  confirmation_token              :string(255)
#  confirmed_at                    :datetime
#  country                         :string(255)
#  created_at                      :datetime         not null
#  current_sign_in_at              :datetime
#  current_sign_in_ip              :string(255)
#  early_access                    :text
#  email                           :string(255)      default(""), not null
#  encrypted_password              :string(128)      default(""), not null
#  enthusiast_id                   :integer
#  failed_attempts                 :integer          default(0)
#  hidden_notice_ids               :text
#  id                              :integer          not null, primary key
#  invitation_accepted_at          :datetime
#  invitation_limit                :integer
#  invitation_sent_at              :datetime
#  invitation_token                :string(60)
#  invited_by_id                   :integer
#  invited_by_type                 :string(255)
#  last_failed_cc_authorize_at     :datetime
#  last_failed_cc_authorize_error  :string(255)
#  last_failed_cc_authorize_status :integer
#  last_invoiced_amount            :integer          default(0)
#  last_sign_in_at                 :datetime
#  last_sign_in_ip                 :string(255)
#  locked_at                       :datetime
#  name                            :string(255)
#  newsletter                      :boolean          default(FALSE)
#  password_salt                   :string(255)      default(""), not null
#  pending_cc_expire_on            :date
#  pending_cc_last_digits          :string(255)
#  pending_cc_type                 :string(255)
#  pending_cc_updated_at           :datetime
#  postal_code                     :string(255)
#  referrer_site_token             :string(255)
#  remember_created_at             :datetime
#  remember_token                  :string(255)
#  reset_password_sent_at          :datetime
#  reset_password_token            :string(255)
#  sign_in_count                   :integer          default(0)
#  state                           :string(255)
#  total_invoiced_amount           :integer          default(0)
#  unconfirmed_email               :string(255)
#  updated_at                      :datetime         not null
#  use_clients                     :boolean
#  use_company                     :boolean
#  use_personal                    :boolean
#  vip                             :boolean          default(FALSE)
#  zendesk_id                      :integer
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

