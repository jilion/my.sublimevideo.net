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

    it { should belong_to :suspending_delayed_job }
    it { should have_many :sites }
    it { should have_many :invoices }
  end

  describe "Scopes" do
    before(:all) do
      User.delete_all
      # Billable because of 1 paid plan
      @user1 = Factory(:user)
      Factory(:site, user: @user1, plan: @paid_plan)
      Factory(:site, user: @user1, plan: @dev_plan)

      # Billable because next cycle plan is another paid plan
      @user2 = Factory(:user)
      Factory(:site, user: @user2, plan: @paid_plan, next_cycle_plan: Factory(:plan))

      # Not billable because next cycle plan is the dev plan
      @user3 = Factory(:user)
      Factory(:site, user: @user3, plan: @paid_plan, next_cycle_plan: @dev_plan)

      # Not billable because his site has been archived
      @user4 = Factory(:user)
      Factory(:site, user: @user4, state: "archived", archived_at: Time.utc(2010,2,28))

      # Billable because next cycle plan is another paid plan, but not active
      @user5 = Factory(:user, state: 'suspended')
      Factory(:site, user: @user5, plan: @paid_plan, next_cycle_plan: Factory(:plan))

      # Not billable nor active
      @user6 = Factory(:user, state: 'archived')
    end

    describe "#billable" do
      specify { User.billable.should == [@user1, @user2, @user5] }
    end

    describe "#not_billable" do
      specify { User.not_billable.should == [@user3, @user4, @user6] }
    end

    describe "#active_and_billable" do
      specify { User.active_and_billable.should == [@user1, @user2] }
    end

    describe "#active_and_not_billable" do
      specify { User.active_and_not_billable.should == [@user3, @user4] }
    end

  end

  describe "Validations" do
    [:first_name, :last_name, :email, :remember_me, :password, :postal_code, :country, :use_personal, :use_company, :use_clients, :company_name, :company_url, :company_job_title, :company_employees, :company_videos_served, :terms_and_conditions, :cc_update, :cc_type, :cc_full_name, :cc_number, :cc_expire_on, :cc_verification_value].each do |attr|
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
          user = Factory.build(:user, :email => active_user.email)
          user.should_not be_valid
          user.should have(1).error_on(:email)
        end
      end

      context "email already taken by an archived user" do
        it "should not add an error" do
          archived_user = Factory(:user, :state => 'archived', :email => "john@doe.com")
          user = Factory.build(:user, :email => archived_user.email)
          user.should be_valid
          user.errors.should be_empty
        end
      end
    end

    it "should validate presence of at least one usage" do
      user = Factory.build(:user, :use_personal => nil, :use_company => nil, :use_clients => nil)
      user.should_not be_valid
      user.should have(1).error_on(:use)
      user.errors[:use].should == ["Please check at least one option"]
    end

    context "when use_company is checked" do
      it "should validate company fields if use_company is checked" do
        fields = [:company_name, :company_url, :company_job_title, :company_employees, :company_videos_served]
        user = Factory.build(:user, Hash[fields.map { |f| [f, nil] }].merge({ :use_personal => false, :use_company => true }))
        user.should_not be_valid
        fields.each do |f|
          user.should have(1).error_on(f)
        end
      end

      it "should validate company url" do
        user = Factory.build(:user, :use_company => true, :company_url => "http://localhost")
        user.should_not be_valid
        user.should have(1).error_on(:company_url)
      end
    end

    describe "user credit card when at least 1 credit card field is given" do
      it "should be valid without any credit card field" do
        user = Factory.build(:user, :cc_update => nil, :cc_number => nil, :cc_first_name => nil, :cc_last_name => nil, :cc_verification_value => nil, :cc_expire_on => nil)
        user.should be_valid
      end

      context "with at least a credit card field given" do
        it "should require first and last name" do
          user = Factory.build(:user, :cc_expire_on => 1.year.from_now, :cc_first_name => "Bob")
          user.should_not be_valid
          user.should have(1).error_on(:cc_full_name)
        end

        it "should not allow expire date in the future" do
          user = Factory.build(:user, :cc_full_name => "John Doe", :cc_expire_on => 1.year.ago)
          user.should_not be_valid
          user.should have(2).errors_on(:cc_expire_on)
        end

        describe "credit card number" do
          it "should require one" do
            user = Factory.build(:user, :cc_expire_on => 1.year.from_now, :cc_full_name => "John Doe")
            user.should_not be_valid
            user.should have(1).error_on(:cc_number)
          end

          it "should require a valid one" do
            user = Factory.build(:user, :cc_expire_on => 1.year.from_now, :cc_full_name => "John Doe", :cc_number => '1234')
            user.should_not be_valid
            user.should have(1).error_on(:cc_number)
          end
        end

        describe "credit card type" do
          it "should require one" do
            user = Factory.build(:user, :cc_type => nil, :cc_expire_on => 1.year.from_now, :cc_full_name => "John Doe")
            user.should_not be_valid
            user.should have(2).errors_on(:cc_type)
          end

          it "should require a valid one" do
            user = Factory.build(:user, :cc_type => 'foo', :cc_expire_on => 1.year.from_now, :cc_full_name => "John Doe")
            user.should_not be_valid
            user.should have(1).error_on(:cc_type)
          end
        end

        it "should require a credit card verification value" do
          user = Factory.build(:user, :cc_expire_on => 1.year.from_now, :cc_full_name => "John Doe")
          user.should_not be_valid
          user.should have(1).error_on(:cc_verification_value)
        end
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

  pending "State Machine" do
    before(:all) do
      @user     = Factory(:user)
      @dev_site = Factory(:site,    :user => @user, :plan => Factory(:dev_plan), :hostname => "octavez.com")
      @invoice1 = Factory(:invoice, :user => @user, :state => 'failed', :started_at => Time.utc(2010,2), :ended_at => Time.utc(2010,3))
      @invoice2 = Factory(:invoice, :user => @user, :state => 'failed', :started_at => Time.utc(2010,3), :ended_at => Time.utc(2010,4))
    end

    describe "Initial State" do
      subject { @user }
      it { should be_active }
    end

    describe "#suspend" do
      before(:all) do
        @active_site = Factory(:site, :user => @user, :hostname => "rymai.com", :state => 'active')
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
        describe "before_transition :on => :suspend, :do => :set_failed_invoices_count_on_suspend" do
          specify do
            subject.reload.failed_invoices_count_on_suspend.should == 0
            subject.suspend
            subject.failed_invoices_count_on_suspend.should == 2
          end
        end

        describe "before_transition :on => :suspend, :do => :suspend_sites" do
          it "should suspend each user' active site" do
            @active_site.reload.should be_active
            @dev_site.reload.should be_dev
            subject.reload.suspend
            @active_site.reload.should be_suspended
            @dev_site.reload.should be_dev
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

    describe "#cancel_suspend" do
      before(:each) do
        @user.reload.delay_suspend
      end
      subject { @user }

      context "from active state" do
        it "should set user to active" do
          subject.should be_active
          subject.cancel_suspend
          subject.should be_active
        end
      end

      describe "Callbacks" do
        describe "before_transition :on => :cancel_suspend, :do => :delete_suspending_delayed_job" do
          it "should clear the delayed job scheduled to suspend the user" do
            delayed_job_id = subject.suspending_delayed_job_id
            Delayed::Job.find(delayed_job_id).should be_present
            subject.cancel_suspend
            lambda { Delayed::Job.find(delayed_job_id) }.should raise_error(ActiveRecord::RecordNotFound)
          end

          it "should clear suspending_delayed_job_id" do
            subject.suspending_delayed_job_id.should be_present
            subject.cancel_suspend
            subject.suspending_delayed_job_id.should be_nil
          end
        end
      end
    end

    describe "#unsuspend" do
      before(:all) do
        @suspended_site = Factory(:site, :user => @user, :hostname => "rymai.me", :state => 'suspended')
      end
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
        describe "before_transition :on => :suspend, :do => :set_failed_invoices_count_on_suspend" do
          before(:all) do
            subject.reload.suspend
          end
          specify do
            subject.failed_invoices_count_on_suspend.should == 2
            @invoice1.reload.update_attribute(:state, 'paid')
            subject.unsuspend
            subject.failed_invoices_count_on_suspend.should == 1
          end
        end

        describe "before_transition :on => :unsuspend, :do => :unsuspend_sites" do
          it "should suspend each user' site" do
            @suspended_site.reload.should be_suspended
            @dev_site.reload.should be_dev
            subject.reload.unsuspend
            @suspended_site.reload.should be_active
            @dev_site.reload.should be_dev
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
        it "should set the user to archived" do
          subject.should be_active
          subject.archive
          subject.should be_archived
        end
      end

      describe "Callbacks" do
        describe "before_transition :on => :archive, :do => [:set_archived_at, :archive_sites, :delay_complete_current_invoice]" do
          specify do
            subject.archived_at.should be_nil
            subject.archive
            subject.archived_at.should be_present
          end

          it "should archive each user' site" do
            @dev_site.reload.should be_dev
            subject.archive
            @dev_site.reload.should be_archived
          end

          it "should delay Class#complete of the usage statement" do
            lambda { subject.archive }.should change(Delayed::Job, :count).by(2)
            Delayed::Job.where(:handler.matches => "%Site%remove_loader_and_license%").count.should == 1
            Delayed::Job.where(:handler.matches => "%Invoice%complete%").count.should == 1
          end
        end

        describe "after_transition  :on => :archive, :do => :send_account_archived_email" do
          it "should send an email to user" do
            lambda { subject.archive }.should change(ActionMailer::Base.deliveries, :count).by(1)
            ActionMailer::Base.deliveries.last.to.should == [subject.email]
          end
        end
      end
    end

  end

  describe "Callbacks" do
    let(:user) { Factory(:user) }

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

    describe "after_update :update_email_on_zendesk" do
      it "should not delay Module#put if email has not changed" do
        user.zendesk_id = 15483194
        Delayed::Job.count.should == 1
      end

      it "should not delay Module#put if user has no zendesk_id" do
        user.email = "new@email.com"
        user.save
        user.email.should == "new@email.com"
        Delayed::Job.count.should == 3
      end

      it "should delay Module#put if the user has a zendesk_id and his email has changed" do
        user.zendesk_id = 15483194
        user.email      = "new@email.com"
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

    describe "after_update :charge_failed_invoices" do
      context "with no failed invoices" do
        it "should not delay Class#charge" do
          user.cc_updated_at = Time.now.utc
          user.save
          Delayed::Job.count.should == 1
        end
      end

      context "with failed invoices" do
        before(:all) do
          @user = Factory(:user)
          Factory(:invoice, :user => @user, :state => 'paid', :started_at => Time.utc(2010,1), :ended_at => Time.utc(2010,2))
          Factory(:invoice, :user => @user, :state => 'failed', :started_at => Time.utc(2010,2), :ended_at => Time.utc(2010,3))
          Factory(:invoice, :user => @user, :state => 'failed', :started_at => Time.utc(2010,3), :ended_at => Time.utc(2010,4))
        end
        subject { @user }

        it "should not delay Class#charge if cc_updated_at has not changed" do
          subject.reload.country = 'FR'
          lambda { subject.save }.should_not change(Delayed::Job, :count)
        end

        it "should delay Class#charge if the user has failed invoices and cc_updated_at has changed" do
          subject.reload.cc_updated_at = Time.now.utc
          lambda { subject.save }.should change(Delayed::Job, :count).by(2)
          Delayed::Job.last.name.should == 'Class#charge'
        end

        context "with a suspended user" do
          before(:all) { subject.reload.update_attribute(:state, 'suspended') }

          it "should delay Class#charge if the user has failed invoices and cc_updated_at has changed" do
            subject.cc_updated_at = Time.now.utc
            lambda { subject.save }.should change(Delayed::Job, :count).by(2)
            Delayed::Job.last.name.should == 'Class#charge'
          end
        end
      end
    end
  end

  describe "attributes accessor" do
    describe "email=" do
      it "should downcase email" do
        user = Factory.build(:user, :email => "BOB@cool.com")
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

    describe "#get_discount?" do
      specify { Factory(:user, :remaining_discounted_months => nil).should_not be_get_discount }
      specify { Factory(:user, :remaining_discounted_months => 0).should_not be_get_discount }
      specify { Factory(:user, :remaining_discounted_months => 1).should be_get_discount }
    end

    describe "#have_beta_sites?" do
      before(:all) { @site = Factory(:site, :plan => @beta_plan) }

      specify { @site.user.have_beta_sites?.should be_true }
    end

    describe "#delay_suspend" do
      before(:all) { @user = Factory(:user) }
      subject { @user.reload.delay_suspend }

      it "should delay suspend user" do
        lambda { subject }.should change(Delayed::Job, :count).by(1)
        Delayed::Job.last.name.should == "Class#suspend"
      end

      it "should delay charging in Billing.days_before_suspend_user.days.from_now by default" do
        subject
        Delayed::Job.last.run_at.should be_within(5).of(Billing.days_before_suspend_user.days.from_now) # seconds of tolerance
      end

      it "should set suspending_delayed_job_id" do
        @user.reload.suspending_delayed_job_id.should be_nil
        subject
        @user.reload.suspending_delayed_job_id.should == Delayed::Job.last.id
      end

      context "giving a custom run_at" do
        specify do
          @user.delay_suspend(Time.utc(2010,7,24))
          Delayed::Job.last.run_at.should == Time.utc(2010,7,24)
        end
      end

      context "with an exception raised by User.delay.suspend" do
        before(:each) do
          User.should_receive(:delay).and_raise("Exception")
          Notify.stub!(:send)
        end

        specify { expect { subject }.to_not raise_error }

        it "should not delay suspend user" do
          lambda { subject }.should_not change(Delayed::Job, :count)
        end
        it "should Notify of the exception" do
          Notify.should_receive(:send)
          subject
        end
        it "should not set suspending_delayed_job_id" do
          @user.reload.suspending_delayed_job_id.should be_nil
          subject
          @user.reload.suspending_delayed_job_id.should be_nil
        end
      end
    end # #delay_suspend

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
      :company_job_title => "Boss",
      :company_employees => "101-1'000",
      :company_videos_served => "0-1'000",
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
#  id                               :integer         not null, primary key
#  state                            :string(255)
#  email                            :string(255)     default(""), not null
#  encrypted_password               :string(128)     default(""), not null
#  password_salt                    :string(255)     default(""), not null
#  confirmation_token               :string(255)
#  confirmed_at                     :datetime
#  confirmation_sent_at             :datetime
#  reset_password_token             :string(255)
#  remember_token                   :string(255)
#  remember_created_at              :datetime
#  sign_in_count                    :integer         default(0)
#  current_sign_in_at               :datetime
#  last_sign_in_at                  :datetime
#  current_sign_in_ip               :string(255)
#  last_sign_in_ip                  :string(255)
#  failed_attempts                  :integer         default(0)
#  locked_at                        :datetime
#  cc_type                          :string(255)
#  cc_last_digits                   :integer
#  cc_expire_on                     :date
#  cc_updated_at                    :datetime
#  created_at                       :datetime
#  updated_at                       :datetime
#  invitation_token                 :string(20)
#  invitation_sent_at               :datetime
#  zendesk_id                       :integer
#  enthusiast_id                    :integer
#  first_name                       :string(255)
#  last_name                        :string(255)
#  postal_code                      :string(255)
#  country                          :string(255)
#  use_personal                     :boolean
#  use_company                      :boolean
#  use_clients                      :boolean
#  company_name                     :string(255)
#  company_url                      :string(255)
#  company_job_title                :string(255)
#  company_employees                :string(255)
#  company_videos_served            :string(255)
#  suspending_delayed_job_id        :integer
#  failed_invoices_count_on_suspend :integer         default(0)
#  archived_at                      :datetime
#  remaining_discounted_months      :integer
#  newsletter                       :boolean         default(TRUE)
#  last_invoiced_amount             :integer         default(0)
#  total_invoiced_amount            :integer         default(0)
#
# Indexes
#
#  index_users_on_confirmation_token     (confirmation_token) UNIQUE
#  index_users_on_created_at             (created_at)
#  index_users_on_current_sign_in_at     (current_sign_in_at)
#  index_users_on_email_and_archived_at  (email,archived_at) UNIQUE
#  index_users_on_last_invoiced_amount   (last_invoiced_amount)
#  index_users_on_reset_password_token   (reset_password_token) UNIQUE
#  index_users_on_total_invoiced_amount  (total_invoiced_amount)
#

