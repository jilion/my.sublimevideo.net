require 'spec_helper'

describe User do

  context "Factory" do
    before(:all) { @user = Factory(:user) }
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
    before(:all) { @user = Factory(:user) }
    subject { @user }

    it { should have_many :sites }
    it { should have_many(:invoices).through(:sites) }
  end

  describe "Scopes" do
    before(:all) do
      User.delete_all
      # Billable because of 1 paid plan
      @user1 = Factory(:user)
      Factory(:site, user: @user1, plan_id: @paid_plan.id)
      Factory(:site, user: @user1, plan_id: @dev_plan.id)

      # Billable because next cycle plan is another paid plan
      @user2 = Factory(:user)
      Factory(:site, user: @user2, plan_id: @paid_plan.id).update_attribute(:next_cycle_plan_id, Factory(:plan).id)

      # Not billable because next cycle plan is the dev plan
      @user3 = Factory(:user)
      Factory(:site, user: @user3, plan_id: @paid_plan.id).update_attribute(:next_cycle_plan_id, @dev_plan.id)

      # Not billable because his site has been archived
      @user4 = Factory(:user)
      Factory(:site, user: @user4, state: 'archived', archived_at: Time.utc(2010,2,28))

      # Billable because next cycle plan is another paid plan, but not active
      @user5 = Factory(:user, state: 'suspended')
      Factory(:site, user: @user5, plan_id: @paid_plan.id).update_attribute(:next_cycle_plan_id, Factory(:plan).id)

      # Not billable nor active
      @user6 = Factory(:user, state: 'archived')
    end

    describe "#billable" do
      specify { User.billable.order(:id).map(&:id).should =~ [@user1, @user2, @user5].map(&:id) }
    end

    describe "#not_billable" do
      specify { User.not_billable.order(:id).map(&:id).should == [@user3, @user4, @user6].map(&:id) }
    end

    describe "#active_and_billable" do
      specify { User.active_and_billable.order(:id).map(&:id).should == [@user1, @user2].map(&:id) }
    end

    describe "#active_and_not_billable" do
      specify { User.active_and_not_billable.order(:id).map(&:id).should == [@user3, @user4].map(&:id) }
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
    it { should validate_presence_of(:country) }
    it { should validate_acceptance_of(:terms_and_conditions) }

    describe "validates uniqueness of email among non-archived users only" do
      context "email already taken by an active user" do
        it "should add an error" do
          active_user = Factory(:user, :state => 'active', :email => "john@doe.com")
          user = Factory.build(:user, email: active_user.email)
          user.should_not be_valid
          user.should have(1).error_on(:email)
        end
      end

      context "email already taken by an archived user" do
        it "should not add an error" do
          archived_user = Factory(:user, state: 'archived', email: "john@doe.com")
          user = Factory.build(:user, email: archived_user.email)
          user.should be_valid
          user.errors.should be_empty
        end
      end
    end

    it "should validate presence of at least one usage" do
      user = Factory.build(:user, :use_personal => nil, :use_company => nil, :use_clients => nil)
      user.should be_valid
    end

    it "should validate company url" do
      user = Factory.build(:user, :use_company => true, :company_url => "http://localhost")
      user.should_not be_valid
      user.should have(1).error_on(:company_url)
    end

    context "when update email" do
      it "should validate current_password presence" do
        user = Factory(:user)
        user.update_attributes(:email => "bob@doe.com").should be_false
        user.errors[:current_password].should == ["can't be blank"]
      end

      it "should validate current_password" do
        user = Factory(:user)
        user.update_attributes(:email => "bob@doe.com", :current_password => "wrong").should be_false
        user.errors[:current_password].should == ["is invalid"]
      end

      it "should not validate current_password with other errors" do
        user = Factory(:user)
        user.update_attributes(:password => "newone", :email => 'wrong').should be_false
        user.errors[:current_password].should be_empty
      end
    end

    context "when update password" do
      it "should validate current_password presence" do
        user = Factory(:user)
        user.update_attributes(:password => "newone").should be_false
        user.errors[:current_password].should == ["can't be blank"]
      end

      it "should validate current_password" do
        user = Factory(:user)
        user.update_attributes(:password => "newone", :current_password => "wrong").should be_false
        user.errors[:current_password].should == ["is invalid"]
      end

      it "should not validate current_password with other errors" do
        user = Factory(:user)
        user.update_attributes(:password => "newone", :email => '').should be_false
        user.errors[:current_password].should be_empty
      end
    end

    context "when archive" do
      it "should validate current_password presence" do
        user = Factory(:user)
        user.archive.should be_false
        user.errors[:current_password].should == ["can't be blank"]
      end

      it "should validate current_password" do
        user = Factory(:user)
        user.current_password = 'wrong'
        user.archive.should be_false
        user.errors[:current_password].should == ["is invalid"]
      end
    end
  end

  context "invited" do
    subject { Factory(:user).tap { |u| u.send(:attributes=, { :invitation_token => '123', :invitation_sent_at => Time.now, :email => "bob@bob.com", :enthusiast_id => 12 }, false); u.save(:validate => false) } }

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
      @user           = Factory(:user)
      @dev_site       = Factory(:site, user: @user, plan_id: @dev_plan.id, hostname: "octavez.com")
      @paid_site      = Factory(:site, user: @user, hostname: "rymai.com")
      @suspended_site = Factory(:site, user: @user, hostname: "rymai.me", state: 'suspended')
      @invoice1       = Factory(:invoice, site: @paid_site, state: 'failed')
      @invoice2       = Factory(:invoice, site: @paid_site, state: 'failed')
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
          it "should suspend each user' active site" do
            @paid_site.reload.should be_active
            @dev_site.reload.should be_active
            subject.reload.suspend
            @paid_site.reload.should be_suspended
            @dev_site.reload.should be_active
          end
        end

        describe "after_transition  :on => :suspend, :do => :send_account_suspended_email" do
          it "should send an email to invoice.user" do
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
          it "should suspend each user' site" do
            @suspended_site.reload.should be_suspended
            @dev_site.reload.should be_active
            subject.reload.unsuspend
            @suspended_site.reload.should be_active
            @dev_site.reload.should be_active
          end
        end

        describe "after_transition  :on => :unsuspend, :do => :send_account_unsuspended_email" do
          it "should send an email to user" do
            lambda { subject.unsuspend }.should change(ActionMailer::Base.deliveries, :count).by(1)
            ActionMailer::Base.deliveries.last.to.should == [subject.email]
          end
        end
      end
    end

    describe "#archive" do
      before(:each) { @user.reload.update_attribute(:state, 'active') }
      subject { @user.reload }

      context "from active state" do
        it "should require current_password" do
          subject.should be_active
          subject.archive
          subject.should_not be_archived
        end

        it "should set the user to archived" do
          subject.should be_active
          subject.current_password = "123456"
          subject.archive
          subject.should be_archived
        end
      end

      describe "Callbacks" do
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

        describe "after_transition :on => :archive, :do => :send_account_archived_email" do
          it "should send an email to user" do
            lambda { subject.current_password = "123456"; subject.archive }.should change(ActionMailer::Base.deliveries, :count).by(1)
            ActionMailer::Base.deliveries.last.to.should == [subject.email]
          end
        end
      end
    end

  end

  describe "Callbacks" do
    let(:user) { Factory(:user) }

    describe "before_save :pend_credit_card_info" do

      context "when user has no cc infos before" do
        subject { Factory.build(:user_no_cc, valid_cc_attributes) }
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
        subject { Factory(:user) }
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

    describe "after_save :newsletter_subscription" do
      use_vcr_cassette "campaign_monitor/user"
      let(:user) { Factory(:user, :newsletter => "1", :email => "newsletter@jilion.com") }

      it "should subscribe on user creation" do
        user
        @worker.work_off
        CampaignMonitor.state(user.email).should == "Active"
      end

      it "should not subscribe on user creation if newsletter is false" do
        user = Factory(:user, :newsletter => "0", :email => "no_newsletter@jilion.com")
        @worker.work_off
        CampaignMonitor.state(user.email).should == "Unknown"
      end

      it "should subscribe new email and unsubscribe old email on user email update" do
        old_email = user.email
        @worker.work_off
        CampaignMonitor.state(user.email).should == "Active"
        user.update_attributes(:email => "new@jilion.com")
        @worker.work_off
        CampaignMonitor.state(old_email).should == "Unsubscribed"
        CampaignMonitor.state(user.email).should == "Active"
      end

      it "should do nothing if user just change is name" do
        user
        @worker.work_off
        user.update_attributes(:first_name => "bob")
        Delayed::Job.count.should == 0
      end
    end

    pending "after_create :push_new_registration" do
      it "should delay on Ding class" do
        Ding.should_receive(:delay)
        Factory(:user)
      end
      
      it "should send a ding!" do
        expect { Factory(:user) }.to change(Delayed::Job, :count)
        djs = Delayed::Job.where(:handler.matches => "%signup%")
        djs.count.should == 1
        djs.first.name.should == 'Class#signup'
      end
    end

    describe "after_update :update_email_on_zendesk" do
      it "should not delay Module#put if email has not changed" do
        user.zendesk_id = 15483194
        Delayed::Job.count.should == 1
      end

      it "should not delay Module#put if user has no zendesk_id" do
        user.email            = "new@email.com"
        user.current_password = '123456'
        user.save
        user.email.should == "new@email.com"
        Delayed::Job.count.should == 3
      end

      it "should delay Module#put if the user has a zendesk_id and his email has changed" do
        user.zendesk_id       = 15483194
        user.email            = "new@email.com"
        user.current_password = '123456'
        user.save
        user.email.should == "new@email.com"
        Delayed::Job.all.any? { |dj| dj.name == 'Module#put' }.should be_true
      end

      it "should update user's email on Zendesk if this user has a zendesk_id and his email has changed" do
        user.zendesk_id = 15483194
        user.email      = "new@email.com"
        user.save
        VCR.use_cassette("user/update_email_on_zendesk") { @worker.work_off }
        Delayed::Job.last.should be_nil
        VCR.use_cassette("user/email_on_zendesk_after_update") do
          JSON.parse(Zendesk.get("/users/15483194/user_identities.json").body).select { |h| h["identity_type"] == "email" }.map { |h| h["value"] }.should include("new@email.com")
        end
      end
    end

    # describe "after_update :charge_failed_invoices" do
    #   context "with no failed invoices" do
    #     it "should not delay Class#charge" do
    #       user.cc_updated_at = Time.now.utc
    #       user.save
    #       Delayed::Job.count.should == 1
    #     end
    #   end
    # 
    #   context "with failed invoices" do
    #     before(:all) do
    #       @user  = Factory(:user)
    #       @site1 = Factory(:site, user: @user)
    #       @site2 = Factory(:site, user: @user)
    #       Factory(:invoice, site: @site1, state: 'paid')
    #       Factory(:invoice, site: @site2, state: 'failed')
    #     end
    #     subject { @user }
    # 
    #     it "should not delay Class#charge if cc_updated_at has not changed" do
    #       subject.reload.country = 'FR'
    #       lambda { subject.save }.should_not change(Delayed::Job, :count)
    #     end
    # 
    #     it "should delay Class#charge if the user has failed invoices and cc_updated_at has changed" do
    #       subject.reload.cc_updated_at = Time.now.utc
    #       lambda { subject.save }.should change(Delayed::Job, :count).by(1)
    #       Delayed::Job.last.name.should == 'Class#charge_open_and_failed_invoices_by_user_id'
    #     end
    # 
    #     context "with a suspended user" do
    #       before(:all) { subject.reload.update_attribute(:state, 'suspended') }
    # 
    #       it "should delay Class#charge if the user has failed invoices and cc_updated_at has changed" do
    #         subject.cc_updated_at = Time.now.utc
    #         lambda { subject.save }.should change(Delayed::Job, :count).by(1)
    #         Delayed::Job.last.name.should == 'Class#charge_open_and_failed_invoices_by_user_id'
    #       end
    #     end
    #   end
    # end
    
  end

  describe "attributes accessor" do
    describe "email=" do
      it "should downcase email" do
        user = Factory.build(:user, email: "BOB@cool.com")
        user.email.should == "bob@cool.com"
      end
    end
  end

  describe "Instance Methods" do
    let(:user) { Factory(:user) }

    describe "#active?" do
      it "should be active when suspended in order to allow login" do
        user.suspend
        user.should be_active
      end
    end

    describe "#have_beta_sites?" do
      before(:all) { @site = Factory(:site, plan_id: @beta_plan.id) }

      specify { @site.user.have_beta_sites?.should be_true }
    end

    describe "#beta?" do
      context "with active beta user" do
        subject { Factory(:user, created_at: Time.utc(2010,10,10), invitation_token: nil) }

        its(:beta?) { should be_true }
      end
      context "with un active beta user" do
        subject { Factory(:user, created_at: Time.utc(2010,10,10), invitation_token: 'xxx') }

        its(:beta?) { should be_false }
      end
      context "with a standard user (limit)" do
        subject { Factory(:user, created_at: Time.utc(2011,3,29).midnight, invitation_token: nil) }

        its(:beta?) { should be_false }
      end
      context "with a standard user" do
        subject { Factory(:user, created_at: Time.utc(2011,3,30), invitation_token: nil) }

        its(:beta?) { should be_false }
      end
    end

    describe "#vat?" do
      context "with Swiss user" do
        subject { Factory(:user, country: 'CH') }

        its(:vat?) { should be_true }
      end
      context "with USA user" do
        subject { Factory(:user, country: 'US') }

        its(:vat?) { should be_false }
      end
    end

    describe "#invoices_failed?" do
      before(:all) do
        @user = Factory(:user)
        @site = Factory(:site, user: @user)
        Factory(:invoice, state: 'failed', site: @site)
      end
      subject { @user }

      its(:invoices_failed?) { should be_true }
    end

    describe "#invoices_waiting?" do
      before(:all) do
        @user = Factory(:user)
        @site = Factory(:site, user: @user)
        Factory(:invoice, state: 'waiting', site: @site)
      end
      subject { @user }

      its(:invoices_waiting?) { should be_true }
    end

    describe "#invoices_open?" do
      before(:all) do
        @user = Factory(:user)
        @site = Factory(:site, user: @user)
        Factory(:invoice, state: 'open', site: @site)
      end
      subject { @user }

      its(:invoices_open?) { should be_true }
    end

    describe "#support" do
      context "user has no site" do
        before(:all) do
          @user = Factory(:user)
        end
        subject { @user.reload }

        it { subject.support.should == "launchpad" }
      end

      context "user has a site with no plan" do
        before(:all) do
          @user = Factory(:user)
          @site = Factory(:site, user: @user)
          @site.send(:write_attribute, :plan_id, nil)
          @site.save(validate: false)
          @site.plan_id.should be_nil
        end
        subject { @user.reload }

        it { subject.support.should == "launchpad" }
      end

      context "user has only sites with launchpad support" do
        before(:all) do
          @user = Factory(:user)
          Factory(:site, user: @user, plan_id: @dev_plan.id)
        end
        subject { @user.reload }

        it { @dev_plan.support.should == "launchpad" }
        it { subject.support.should == "launchpad" }
      end

      context "user has only sites with standard support" do
        before(:all) do
          @user = Factory(:user)
          Factory(:site, user: @user, plan_id: @paid_plan.id)
          Factory(:site, user: @user, plan_id: @beta_plan.id)
        end
        subject { @user.reload }

        it { @paid_plan.support.should == "standard" }
        it { @beta_plan.support.should == "standard" }
        it { subject.support.should == "standard" }
      end

      context "user has at least one site with priority support" do
        before(:all) do
          @user = Factory(:user)
          Factory(:site, user: @user, plan_id: @paid_plan.id)
          Factory(:site, user: @user, plan_id: @custom_plan.token)
        end
        subject { @user.reload }

        it { @paid_plan.support.should == "standard" }
        it { @custom_plan.support.should == "priority" }
        it { subject.support.should == "priority" }
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
#  password_salt          :string(255)     default(""), not null
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  reset_password_token   :string(255)
#  remember_token         :string(255)
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

