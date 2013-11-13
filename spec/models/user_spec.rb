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

    describe '#terms_and_conditions' do
      subject { super().terms_and_conditions }
      it { should be_truthy }
    end

    describe '#name' do
      subject { super().name }
      it                 { should eq "John Doe" }
    end

    describe '#billing_email' do
      subject { super().billing_email }
      it        { should match /email\d+@user.com/ }
    end

    describe '#billing_name' do
      subject { super().billing_name }
      it         { should eq "Remy Coutable" }
    end

    describe '#billing_address_1' do
      subject { super().billing_address_1 }
      it    { should eq "Avenue de France 71" }
    end

    describe '#billing_address_2' do
      subject { super().billing_address_2 }
      it    { should eq "Batiment B" }
    end

    describe '#billing_postal_code' do
      subject { super().billing_postal_code }
      it  { should eq "1004" }
    end

    describe '#billing_city' do
      subject { super().billing_city }
      it         { should eq "Lausanne" }
    end

    describe '#billing_region' do
      subject { super().billing_region }
      it       { should eq "VD" }
    end

    describe '#billing_country' do
      subject { super().billing_country }
      it      { should eq "CH" }
    end

    describe '#use_personal' do
      subject { super().use_personal }
      it         { should be_truthy }
    end

    describe '#newsletter' do
      subject { super().newsletter }
      it           { should be_falsey }
    end

    describe '#email' do
      subject { super().email }
      it                { should match /email\d+@user.com/ }
    end

    describe '#hidden_notice_ids' do
      subject { super().hidden_notice_ids }
      it    { should eq [] }
    end

    describe '#vip' do
      subject { super().vip }
      it                  { should be_falsey }
    end

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
    # Devise checks presence/uniqueness/format of email, presence/length of password
    it { should validate_presence_of(:email) }
    it { should allow_value('test@example.com').for(:billing_email) }
    it { should_not allow_value('example.com').for(:billing_email) }
    it { should ensure_length_of(:billing_postal_code).is_at_most(20) }
    it { should validate_acceptance_of(:terms_and_conditions) }

    describe "email" do
      context "email already taken by an active user" do
        it "is not valid" do
          active_user = create(:user, state: 'active', email: "john@doe.com")
          user = build(:user, email: active_user.email)
          expect(user).not_to be_valid
          expect(user.errors[:email].size).to eq(1)
        end
      end

      context "email already taken by an archived user" do
        it "is valid" do
          archived_user = create(:user, state: 'archived', email: "john@doe.com")
          user = build(:user, email: archived_user.email)
          expect(user).to be_valid
        end
      end
    end

    describe "company_url" do
      context "is present" do
        it "is not valid" do
          user = build(:user, use_company: true, company_url: "http://localhost")
          expect(user).not_to be_valid
          expect(user.errors[:company_url].size).to eq(1)
        end
      end

      context "is not present" do
        it "is valid" do
          user = build(:user, use_company: true, company_url: "")
          expect(user).to be_valid
        end
      end
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

    describe "#archive" do
      [:active, :suspended].each do |state|
        context "from #{state} state" do
          before { user.update_attribute(:state, state) }

          it "sets the user to archived" do
            expect(user.state).to eq state
            user.current_password = "123456"

            user.archive!

            expect(user).to be_archived
          end

          it 'touches archived_at' do
            expect(user.archived_at).to be_nil
            user.current_password = "123456"

            user.archive!

            expect(user.archived_at).to be_present
          end
        end
      end
    end
  end

  describe "Callbacks" do

    describe "before_save :prepare_pending_credit_card & after_save :register_credit_card_on_file" do

      context "when user had no cc info before", :vcr do
        subject do
          user = create(:user_no_cc)
          user.reload
          user.update(valid_cc_attributes)
          user
        end

        it { should be_valid }

        describe '#cc_type' do
          subject { super().cc_type }
          it        { should eq 'visa' }
        end

        describe '#cc_last_digits' do
          subject { super().cc_last_digits }
          it { should eq '1111' }
        end

        describe '#cc_expire_on' do
          subject { super().cc_expire_on }
          it   { should eq 1.year.from_now.end_of_month.to_date }
        end

        describe '#pending_cc_type' do
          subject { super().pending_cc_type }
          it        { should be_nil }
        end

        describe '#pending_cc_last_digits' do
          subject { super().pending_cc_last_digits }
          it { should be_nil }
        end

        describe '#pending_cc_expire_on' do
          subject { super().pending_cc_expire_on }
          it   { should be_nil }
        end
      end

      context "when user has cc info before", :vcr do
        subject { create(:user) }
        before do
          expect(subject.cc_type).to eq 'visa'
          expect(subject.cc_last_digits).to eq '1111'
          expect(subject.cc_expire_on).to eq 1.year.from_now.end_of_month.to_date

          subject.attributes = valid_cc_attributes_master
          subject.save!
          subject.reload
        end

        it { should be_valid }

        describe '#cc_type' do
          subject { super().cc_type }
          it        { should eq 'master' }
        end

        describe '#cc_last_digits' do
          subject { super().cc_last_digits }
          it { should eq '9999' }
        end

        describe '#cc_expire_on' do
          subject { super().cc_expire_on }
          it   { should eq 2.years.from_now.end_of_month.to_date }
        end

        describe '#pending_cc_type' do
          subject { super().pending_cc_type }
          it        { should be_nil }
        end

        describe '#pending_cc_last_digits' do
          subject { super().pending_cc_last_digits }
          it { should be_nil }
        end

        describe '#pending_cc_expire_on' do
          subject { super().pending_cc_expire_on }
          it   { should be_nil }
        end
      end
    end

    describe "after_save :_update_newsletter_subscription" do
      context "user sign-up" do
        context "user subscribes to the newsletter" do
          let(:user) { create(:user, id: 1, newsletter: true, email: "newsletter_sign_up@jilion.com") }

          it 'calls NewsletterSubscriptionManager.subscribe' do
            expect(NewsletterSubscriptionManager).to delay(:subscribe).with(1)
            user
          end
        end

        context "user doesn't subscribe to the newsletter" do
          let(:user) { create(:user, newsletter: false, email: "no_newsletter_sign_up@jilion.com") }

          it "doesn't calls NewsletterSubscriptionManager.subscribe" do
            expect(NewsletterSubscriptionManager).not_to delay(:subscribe)
            user
          end
        end
      end
    end

    describe "after_update :_update_newsletter_user_infos" do
      context "user update" do
        let(:user) { create(:user, newsletter: true, email: "newsletter_update@jilion.com") }

        it "registers user's new email on Campaign Monitor and remove old email when user update his email" do
          user.update_attribute(:email, "newsletter_update2@jilion.com")
          expect(NewsletterSubscriptionManager).to delay(:update).with(user.id, "newsletter_update@jilion.com")
          user.confirm!
        end

        it "updates info in Campaign Monitor if user change his name" do
          user
          expect(NewsletterSubscriptionManager).to delay(:update).with(user.id, "newsletter_update@jilion.com")
          user.update_attribute(:name, 'bob')
        end

        it "updates subscribing state in Campaign Monitor if user change his newsletter state" do
          user
          expect(NewsletterSubscriptionManager).to delay(:unsubscribe).with(user.id)
          user.update_attribute(:newsletter, false)
        end
      end
    end

    describe "after_update :_zendesk_update" do
      let(:user) { create(:user) }
      before do
        allow(NewsletterSubscriptionManager).to receive(:sync_from_service)
      end

      context "user has no zendesk_id" do
        it "doesn't delay ZendeskWrapper.update_user" do
          expect(ZendeskWrapper).not_to delay(:update_user)
          user.update_attribute(:email, '9876@example.org')
        end
      end

      context "user has a zendesk_id", :vcr do
        before { user.update_attribute(:zendesk_id, 59438671) }

        context "user updated his email" do
          let(:new_email) { "9877@example.org" }

          it "delays ZendeskWrapper.update_user if the user has a zendesk_id and his email has changed" do
            user.update_attribute(:email, new_email)
            expect(ZendeskWrapper).to delay(:update_user).with(user.zendesk_id, email: new_email)
            user.confirm!
          end

          it "updates user's email on Zendesk if this user has a zendesk_id and his email has changed" do
            user.update_attribute(:email, new_email)
            Sidekiq::Worker.clear_all
            user.confirm!

            Sidekiq::Worker.drain_all
            expect(ZendeskWrapper.user(59438671).identities.last.value).to eq new_email
          end
        end

        context "user updated his name" do
          let(:new_name) { "Remy" }

          it "delays ZendeskWrapper.update_user" do
            expect(ZendeskWrapper).to delay(:update_user).with(user.zendesk_id, name: new_name)
            user.update_attribute(:name, new_name)
          end

          it "updates user's name on Zendesk", :vcr do
            Sidekiq::Worker.clear_all
            user.update_attribute(:name, new_name)

            Sidekiq::Worker.drain_all
            expect(ZendeskWrapper.user(59438671).name).to eq new_name
          end

          context "name has changed to ''" do
            it "doesn't update user's name on Zendesk" do
              expect(ZendeskWrapper).not_to delay(:update_user)
              user.update_attribute(:name, '')
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
        expect(user.email).to eq "bob@cool.com"
      end
    end

    describe "hidden_notice_ids" do
      it "initialize as an array if nil" do
        expect(user.hidden_notice_ids).to eq []
      end

      it "doesn't cast given value" do
        user.hidden_notice_ids << 1 << "foo"
        expect(user.hidden_notice_ids).to eq [1, "foo"]
      end
    end
  end

  describe "Instance Methods" do
    let(:user) { create(:user) }

    describe "#notice_hidden?" do
      before do
        user.hidden_notice_ids << 1
        expect(user.hidden_notice_ids).to eq [1]
      end

      specify { expect(user.notice_hidden?(1)).to be_truthy }
      specify { expect(user.notice_hidden?("1")).to be_truthy }
      specify { expect(user.notice_hidden?(2)).to be_falsey }
      specify { expect(user.notice_hidden?('foo')).to be_falsey }
    end

    describe "#active_for_authentication?" do
      it "should be active for authentication when active" do
        expect(user).to be_active_for_authentication
      end

      it "should be active for authentication when suspended in order to allow login" do
        user.suspend
        expect(user).to be_active_for_authentication
      end

      it "should not be active for authentication when archived" do
        user.archive
        expect(user).not_to be_active_for_authentication
      end
    end

    describe "#beta?" do
      context "with active beta user" do
        subject { create(:user, created_at: Time.utc(2010,10,10), invitation_token: nil) }

        describe '#beta?' do
          subject { super().beta? }
          it { should be_truthy }
        end
      end
      context "with un active beta user" do
        subject { create(:user, created_at: Time.utc(2010,10,10), invitation_token: 'xxx') }

        describe '#beta?' do
          subject { super().beta? }
          it { should be_falsey }
        end
      end
      context "with a standard user (limit)" do
        subject { create(:user, created_at: Time.utc(2011,3,29).midnight, invitation_token: nil) }

        describe '#beta?' do
          subject { super().beta? }
          it { should be_falsey }
        end
      end
      context "with a standard user" do
        subject { create(:user, created_at: Time.utc(2011,3,30), invitation_token: nil) }

        describe '#beta?' do
          subject { super().beta? }
          it { should be_falsey }
        end
      end
    end

    describe "#name_or_email" do
      context "user has no name" do
        subject { create(:user, name: nil, email: 'john@doe.com') }

        describe '#name_or_email' do
          subject { super().name_or_email }
          it { should eq 'john@doe.com' }
        end
      end

      context "user has a name" do
        subject { create(:user, name: 'John Doe', email: 'john@doe.com') }

        describe '#name_or_email' do
          subject { super().name_or_email }
          it { should eq 'John Doe' }
        end
      end
    end

    describe '#billing_name_or_billing_email' do
      context "user has no billing_name" do
        subject { create(:user, billing_name: nil, billing_email: 'dan@jack.com') }

        describe '#billing_name_or_billing_email' do
          subject { super().billing_name_or_billing_email }
          it { should eq 'dan@jack.com' }
        end
      end

      context "user has a billing_name" do
        subject { create(:user, billing_name: 'John Doe', billing_email: 'dan@jack.com') }

        describe '#billing_name_or_billing_email' do
          subject { super().billing_name_or_billing_email }
          it { should eq 'John Doe' }
        end
      end
    end

    describe "#billing_address" do
      context "delegates to snail using billing info" do
        subject { create(:user, full_billing_address) }

        describe '#billing_address' do
          subject { super().billing_address }
          it { should eq "Remy Coutable\nEPFL Innovation Square\nPSE-D\nNew York NY  1015\nUNITED STATES" }
        end
      end

      context "billing_name is missing" do
        subject { create(:user, full_billing_address.merge(billing_name: "")) }

        describe '#billing_address' do
          subject { super().billing_address }
          it { should eq "John Doe\nEPFL Innovation Square\nPSE-D\nNew York NY  1015\nUNITED STATES" }
        end
      end

      context "billing_postal_code is missing" do
        subject { create(:user, full_billing_address.merge(billing_postal_code: "")) }

        describe '#billing_address' do
          subject { super().billing_address }
          it { should eq "Remy Coutable\nEPFL Innovation Square\nPSE-D\nNew York NY  \nUNITED STATES" }
        end
      end

      context "billing_country is missing" do
        subject { create(:user, full_billing_address.merge(billing_country: "")) }

        describe '#billing_address' do
          subject { super().billing_address }
          it { should eq "Remy Coutable\nEPFL Innovation Square\nPSE-D\nNew York NY  1015" }
        end
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

    describe '#billable?' do
      let(:user) { create(:user) }
      let(:site) { create(:site, user: user) }
      subject { user }

      context 'with an add-on in trial' do
        before do
          create(:addon_plan_billable_item, site: site, state: 'trial')
        end

        it { should_not be_billable }
      end

      context 'with an add-on subscribed' do
        before do
          bi = create(:addon_plan_billable_item, site: site, state: 'subscribed')
        end

        it { should be_billable }
      end

      context 'with no add-on subscribed or in trial' do
        before do
          create(:addon_plan_billable_item, site: site, state: 'sponsored')
        end

        it { should_not be_billable }
      end
    end

    describe '#trial_or_billable?' do
      let(:user) { create(:user) }
      let(:site) { create(:site, user: user) }
      subject { user }

      context 'with an add-on in trial' do
        before do
          create(:addon_plan_billable_item, site: site, state: 'trial')
        end

        it { should be_trial_or_billable }
      end

      context 'with an add-on subscribed' do
        before do
          create(:addon_plan_billable_item, site: create(:site, user: user), state: 'subscribed')
        end

        it { should be_trial_or_billable }
      end

      context 'with no add-on subscribed or in trial' do
        before do
          create(:addon_plan_billable_item, site: site, state: 'sponsored')
        end

        it { should_not be_trial_or_billable }
      end
    end

    describe '#sponsored?' do
      let(:user) { create(:user) }
      let(:site) { create(:site, user: user) }
      subject { user }

      context 'with an add-on sponsored' do
        before do
          create(:addon_plan_billable_item, site: site, state: 'sponsored')
        end

        it { should be_sponsored }
      end

      context 'with an add-on subscribed' do
        before do
          create(:addon_plan_billable_item, site: site, state: 'subscribed')
        end

        it { should_not be_sponsored }
      end
    end

  end

  describe "Scopes" do
    describe "state" do
      before do
        @user_invited = create(:user, invitation_token: '123', state: 'archived')
        @user_beta    = create(:user, invitation_token: nil, created_at: PublicLaunch.beta_transition_started_on - 1.day, state: 'suspended')
        @user_active  = create(:user)
      end

      describe ".active" do
        specify { expect(User.active).to match_array([@user_active]) }
      end
    end

    describe "credit card" do
      before do
        @user_no_cc        = create(:user, cc_type: nil, cc_last_digits: nil)
        @user_cc           = create(:user, cc_type: 'visa', cc_last_digits: '1234')
        @user_cc_expire_on = create(:user, cc_expire_on: Time.now.utc.end_of_month.to_date)
        @user_last_credit_card_expiration_notice = create(:user, last_credit_card_expiration_notice_sent_at: 30.days.ago)
      end

      describe ".with_cc" do
        specify { expect(User.with_cc).to match_array([@user_cc, @user_cc_expire_on, @user_last_credit_card_expiration_notice]) }
      end

      describe ".cc_expire_this_month" do
        specify { expect(User.cc_expire_this_month).to match_array([@user_cc_expire_on]) }
      end

      describe ".last_credit_card_expiration_notice_sent_before" do
        specify { expect(User.last_credit_card_expiration_notice_sent_before(15.days.ago)).to match_array([@user_last_credit_card_expiration_notice]) }
        specify { expect(User.last_credit_card_expiration_notice_sent_before(30.days.ago - 1.second)).to be_empty }
      end
    end

    describe "billing", :addons do
      let(:site1) { create(:site) }
      let(:site2) { create(:site) }
      let(:site3) { create(:site) }
      let(:site4) { create(:site, user: create(:user, state: 'suspended')) }
      let(:site5) { create(:site, user: create(:user, state: 'archived')) }
      let(:site6) { create(:site) }
      before do
        create(:billable_item, site: site1, item: create(:addon_plan, price: 995), state: 'beta')
        create(:billable_item, site: site2, item: create(:addon_plan, price: 995), state: 'trial')
        create(:billable_item, site: site3, item: create(:addon_plan, price: 995), state: 'sponsored')
        create(:billable_item, site: site4, item: create(:addon_plan, price: 995), state: 'suspended')
        create(:billable_item, site: site5, item: create(:addon_plan, price: 995), state: 'subscribed')
        create(:billable_item, site: site6, item: create(:addon_plan, price: 995), state: 'subscribed')
      end

      describe ".free" do
        specify { expect(User.free).to match_array([site1.user, site2.user, site3.user]) }
      end

      describe ".paying" do
        specify { expect(User.paying).to match_array([site6.user]) }
      end
    end

    describe ".created_on" do
      before do
        @user1 = create(:user, created_at: 3.days.ago)
        @user2 = create(:user, created_at: 2.days.ago)
      end

      specify { expect(User.created_on(3.days.ago)).to eq [@user1] }
      specify { expect(User.created_on(2.days.ago)).to eq [@user2] }
    end

    describe ".search" do
      before do
        @user1 = create(:user, email: "remy@jilion.com", name: "Marcel Jacques")
        create(:site, user: @user1, hostname: "bob.com")
        # THIS IS HUGELY SLOW DUE TO IPAddr.new('*.dev')!!!!!!!
        # create(:site, user: @user1, dev_hostnames: "foo.dev, bar.dev")
        create(:site, user: @user1, dev_hostnames: "192.168.0.0, 192.168.0.30")
      end

      specify { expect(User.search("remy")).to eq [@user1] }
      specify { expect(User.search("bob")).to eq [@user1] }
      # specify { User.search(".dev").should eq [@user1] }
      specify { expect(User.search("192.168")).to eq [@user1] }
      specify { expect(User.search("marcel")).to eq [@user1] }
      specify { expect(User.search("jacques")).to eq [@user1] }
    end

    describe ".sites_tagged_with" do
      before do
        @user = create(:user).tap { |u| u.tag_list = ['foo']; u.save! }
        @site = create(:site, user: @user).tap { |s| s.tag_list = ['bar']; s.save! }
      end

      it "returns the user that has a site with the given word" do
        expect(Site.tagged_with('bar')).to eq [@site]
        expect(User.sites_tagged_with('bar')).to eq [@user]
      end
    end
  end # Scopes

end

# == Schema Information
#
# Table name: users
#
#  archived_at                                :datetime
#  balance                                    :integer          default(0)
#  billing_address_1                          :string(255)
#  billing_address_2                          :string(255)
#  billing_city                               :string(255)
#  billing_country                            :string(255)
#  billing_email                              :string(255)
#  billing_name                               :string(255)
#  billing_postal_code                        :string(255)
#  billing_region                             :string(255)
#  cc_alias                                   :string(255)
#  cc_expire_on                               :date
#  cc_last_digits                             :string(255)
#  cc_type                                    :string(255)
#  cc_updated_at                              :datetime
#  company_employees                          :string(255)
#  company_job_title                          :string(255)
#  company_name                               :string(255)
#  company_url                                :string(255)
#  company_videos_served                      :string(255)
#  confirmation_comment                       :text
#  confirmation_sent_at                       :datetime
#  confirmation_token                         :string(255)
#  confirmed_at                               :datetime
#  country                                    :string(255)
#  created_at                                 :datetime
#  current_sign_in_at                         :datetime
#  current_sign_in_ip                         :string(255)
#  early_access                               :text
#  email                                      :string(255)      default(""), not null
#  encrypted_password                         :string(128)      default(""), not null
#  enthusiast_id                              :integer
#  failed_attempts                            :integer          default(0)
#  hidden_notice_ids                          :text
#  id                                         :integer          not null, primary key
#  invitation_accepted_at                     :datetime
#  invitation_created_at                      :datetime
#  invitation_limit                           :integer
#  invitation_sent_at                         :datetime
#  invitation_token                           :string(60)
#  invited_by_id                              :integer
#  invited_by_type                            :string(255)
#  last_credit_card_expiration_notice_sent_at :datetime
#  last_failed_cc_authorize_at                :datetime
#  last_failed_cc_authorize_error             :string(255)
#  last_failed_cc_authorize_status            :integer
#  last_invoiced_amount                       :integer          default(0)
#  last_sign_in_at                            :datetime
#  last_sign_in_ip                            :string(255)
#  locked_at                                  :datetime
#  name                                       :string(255)
#  newsletter                                 :boolean          default(FALSE)
#  password_salt                              :string(255)      default(""), not null
#  pending_cc_expire_on                       :date
#  pending_cc_last_digits                     :string(255)
#  pending_cc_type                            :string(255)
#  pending_cc_updated_at                      :datetime
#  postal_code                                :string(255)
#  referrer_site_token                        :string(255)
#  remember_created_at                        :datetime
#  remember_token                             :string(255)
#  reset_password_sent_at                     :datetime
#  reset_password_token                       :string(255)
#  sign_in_count                              :integer          default(0)
#  state                                      :string(255)
#  total_invoiced_amount                      :integer          default(0)
#  unconfirmed_email                          :string(255)
#  updated_at                                 :datetime
#  use_clients                                :boolean
#  use_company                                :boolean
#  use_personal                               :boolean
#  vip                                        :boolean          default(FALSE)
#  zendesk_id                                 :integer
#
# Indexes
#
#  index_users_on_cc_alias               (cc_alias) UNIQUE
#  index_users_on_confirmation_token     (confirmation_token) UNIQUE
#  index_users_on_created_at             (created_at)
#  index_users_on_current_sign_in_at     (current_sign_in_at)
#  index_users_on_email_and_archived_at  (email,archived_at) UNIQUE
#  index_users_on_id_and_state           (id,state)
#  index_users_on_last_invoiced_amount   (last_invoiced_amount)
#  index_users_on_referrer_site_token    (referrer_site_token)
#  index_users_on_reset_password_token   (reset_password_token) UNIQUE
#  index_users_on_total_invoiced_amount  (total_invoiced_amount)
#

