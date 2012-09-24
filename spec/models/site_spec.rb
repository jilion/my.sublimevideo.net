# coding: utf-8
require 'spec_helper'

describe Site, :plans do

  context "Factory" do
    subject { create(:site).reload }

    its(:user)                                    { should be_present }
    its(:hostname)                                { should =~ /jilion[0-9]+\.com/ }
    its(:dev_hostnames)                           { should eq "127.0.0.1,localhost" }
    its(:extra_hostnames)                         { should be_nil }
    its(:path)                                    { should be_nil }
    its(:wildcard)                                { should be_false }
    its(:token)                                   { should =~ /^[a-z0-9]{8}$/ }
    its(:license)                                 { should_not be_present }
    its(:loader)                                  { should_not be_present }
    its(:player_mode)                             { should eq "stable" }
    its(:last_30_days_main_video_views)           { should eq 0 }
    its(:last_30_days_extra_video_views)          { should eq 0 }
    its(:last_30_days_dev_video_views)            { should eq 0 }
    its(:last_30_days_invalid_video_views)        { should eq 0 }
    its(:last_30_days_embed_video_views)          { should eq 0 }
    its(:last_30_days_billable_video_views_array) { should have(30).items }

    it { should be_active } # initial state
    it { should be_valid }
  end

  describe "Associations" do
    let(:site) { create(:site) }
    let(:addon1) { create(:addon, category: 'logo', name: 'no-logo') }
    let(:addon2) { create(:addon, category: 'logo', name: 'custom-logo') }
    let(:addon3) { create(:addon, category: 'support', name: 'vip') }
    subject { site }

    it { should belong_to(:user).validate(true) }
    it { should belong_to :plan }
    it { should have_many :invoices }

    it { should have_many :addonships }

    it { should have_many :bundleships }
    it { should have_many(:bundles).through(:bundleships) }
    it { should have_many(:addons).through(:addonships) }

    describe 'addons scopes' do
      before do
        @addonship1 = create(:addonship, site: site, addon: addon1, state: 'active')
        @addonship2 = create(:addonship, site: site, addon: addon2, state: 'inactive')
        @addonship3 = create(:addonship, site: site, addon: addon3, state: 'active')
      end

      describe 'active addons' do
        it { site.addons.active.should =~ [addon1, addon3] }
      end
    end

    describe "last_invoice" do
      let(:site) { create(:site_with_invoice, plan_id: @paid_plan.id) }

      it "should return the last paid invoice" do
        site.last_invoice.should eq site.invoices.last
      end
    end
  end

  describe "Validations" do
    subject { create(:site) }

    [:hostname, :dev_hostnames, :extra_hostnames, :path, :wildcard, :badged, :plan_id, :user_attributes].each do |attribute|
      it { should allow_mass_assignment_of(attribute) }
    end

    it { should validate_presence_of(:user) }
    it { should ensure_length_of(:path).is_at_most(255) }

    it { should allow_value('dev').for(:player_mode) }
    it { should allow_value('beta').for(:player_mode) }
    it { should allow_value('stable').for(:player_mode) }
    it { should_not allow_value('fake').for(:player_mode) }

    specify { Site.validators_on(:hostname).map(&:class).should eq [HostnameValidator, HostnameUniquenessValidator] }
    specify { Site.validators_on(:extra_hostnames).map(&:class).should include ExtraHostnamesValidator }
    specify { Site.validators_on(:dev_hostnames).map(&:class).should include DevHostnamesValidator }

    describe "no hostnames at all" do
      subject { build(:new_site, hostname: nil, extra_hostnames: nil, dev_hostnames: nil) }
      it { should be_valid } # dev hostnames are set before validation
      it { should have(0).error_on(:base) }
    end

    pending "validates_current_password" do
      context "on a free plan" do
        subject { create(:site, plan_id: @free_plan.id) }

        it "should not validate current_password when modifying settings" do
          subject.update_attributes(hostname: "newone.com").should be_true
          subject.errors[:base].should be_empty
        end
        it "should not validate current_password when modifying plan" do
          VCR.use_cassette('ogone/visa_payment_generic') { subject.update_attributes(plan_id: @paid_plan.id).should be_true }
          subject.errors[:base].should be_empty
        end
      end

      context "on a paid plan" do
        subject { create(:site, plan_id: @paid_plan.id) }

        describe "when updating a site in paid plan" do
          it "needs current_password" do
            subject.update_attributes(plan_id: @custom_plan.token).should be_false
            subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
          end

          it "needs right current_password" do
            subject.update_attributes(plan_id: @custom_plan.token, user_attributes: { current_password: "wrong" }).should be_false
            subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
          end
        end

        describe "when update paid plan settings" do
          it "needs current_password" do
            subject.update_attributes(hostname: "newone.com").should be_false
            subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
          end

          it "needs right current_password" do
            subject.update_attributes(hostname: "newone.com", user_attributes: { current_password: "wrong" }).should be_false
            subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
          end

          it "don't need current_password with other errors" do
            subject.update_attributes(hostname: "", dev_hostnames: "").should be_false
            subject.errors[:base].should be_empty
          end
        end

        describe "when downgrade to free plan" do
          it "needs current_password" do
            subject.update_attributes(plan_id: @free_plan.id).should be_false
            subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
          end

          it "needs right current_password" do
            subject.update_attributes(plan_id: @free_plan.id, user_attributes: { current_password: "wrong" }).should be_false
            subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
          end
        end

        describe "when archive" do
          it "needs current_password" do
            subject.archive.should be_false
            subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
          end

          it "needs right current_password" do
            subject.user.current_password = 'wrong'
            subject.archive.should be_false
            subject.errors[:base].should include I18n.t('activerecord.errors.models.site.attributes.base.current_password_needed')
          end
        end

        describe "when suspend" do
          it "don't need current_password" do
            subject.suspend.should be_true
            subject.errors[:base].should be_empty
          end
        end
      end
    end # validates_current_password

    describe "set_default_addons", :addons do
      subject { create(:site, plan_id: @free_plan.id, badged: nil) }

      its('addons.active') { should =~ [@logo_sublime_addon, @support_standard_addon] }
    end # set_default_addons

  end # Validations

  describe "Attributes Accessors" do
    %w[hostname extra_hostnames dev_hostnames].each do |attr|
      describe "#{attr}=" do
        it "calls Hostname.clean" do
          site = build_stubbed(:new_site)
          Hostname.should_receive(:clean).with("foo.com")

          site.send("#{attr}=", "foo.com")
        end
      end
    end

    describe "#hostname_or_token" do
      context "site with a hostname" do
        subject { build_stubbed(:site, hostname: 'rymai.me') }

        specify { subject.hostname_or_token.should eq 'rymai.me' }
      end

      context "site without a hostname" do
        subject { build_stubbed(:site, plan_id: @free_plan.id, hostname: '') }

        specify { subject.hostname_or_token.should eq "##{subject.token}" }
      end
    end

    describe "path=" do
      describe "sets to '' if nil is given" do
        subject { build_stubbed(:site, path: nil) }

        its(:path) { should eq '' }
      end
      describe "removes first and last /" do
        subject { build_stubbed(:site, path: '/users/thibaud/') }

        its(:path) { should eq 'users/thibaud' }
      end
      describe "downcases path" do
        subject { build_stubbed(:site, path: '/Users/thibaud') }

        its(:path) { should eq 'users/thibaud' }
      end
    end
  end

  describe "State Machine" do
    before { CDN.stub(:purge) }

    pending "#suspend" do
      subject do
        site = build(:new_site)
        site.apply_pending_attributes
        $worker.work_off
        site
      end

      it "should clear & purge license & loader" do
        CDN.should_receive(:purge).with("/js/#{subject.token}.js")
        CDN.should_receive(:purge).with("/l/#{subject.token}.js")
        subject.suspend
        $worker.work_off
        subject.reload.loader.should_not be_present
        subject.license.should_not be_present
      end

      # it "delays Player::Settings.delete!" do
      #   expect { subject.suspend }.to change(Delayed::Job.where{ handler =~ "%Player::Settings%delete!%" }, :count).by(1)
      # end
    end

    pending "#unsuspend" do
      subject do
        site = build(:new_site)
        site.apply_pending_attributes
        $worker.work_off
        site
      end

      it "should reset license & loader" do
        CDN.should_receive(:purge).with("/js/#{subject.token}.js")
        CDN.should_receive(:purge).with("/l/#{subject.token}.js")
        subject.suspend
        $worker.work_off
        subject.reload.loader.should_not be_present
        subject.license.should_not be_present

        subject.unsuspend
        $worker.work_off
        subject.reload.loader.should be_present
        subject.license.should be_present
      end
    end

    pending "#archive" do
      context "from active state" do
        subject do
          site = create(:site)
          $worker.work_off
          site
        end

        it "should clear & purge license & loader and set archived_at" do
          CDN.should_receive(:purge).with("/js/#{subject.token}.js")
          CDN.should_receive(:purge).with("/l/#{subject.token}.js")
          subject.user.current_password = '123456'
          expect { subject.archive! }.to change(
            Delayed::Job.where{ handler =~ "%remove_loader_and_license%" },
            :count
          ).by(1)
          subject.reload.should be_archived
          expect { $worker.work_off }.to change(
            Delayed::Job.where{ handler =~ "%remove_loader_and_license%" },
            :count
          ).by(-1)
          subject.reload.loader.should_not be_present
          subject.license.should_not be_present
          subject.archived_at.should be_present
        end

        # it "delays Player::Settings.delete!" do
        #   subject.user.current_password = '123456'
        #   expect { subject.archive }.to change(
        #     Delayed::Job.where{ handler =~ "%Player::Settings%delete!%" },
        #     :count
        #   ).by(1)
        # end
      end
    end
  end

  describe "Versioning" do
    subject { with_versioning { create(:site) } }

    it "works!" do
      with_versioning do
        old_hostname = subject.hostname
        subject.update_attributes(hostname: "bob.com", user_attributes: { 'current_password' => '123456' })
        subject.versions.last.reify.hostname.should eq old_hostname
      end
    end

    [:cdn_up_to_date, :license, :loader].each do |attr|
      it "doesn't version when :#{attr} changes" do
        with_versioning do
          expect do
            subject.send("#{attr}=", "bob.com")
            subject.save
          end.to_not change(subject.versions, :count)
        end
      end
    end
  end # Versioning

  describe "Callbacks" do

    describe "before_validation" do
      subject { build(:new_site, dev_hostnames: nil) }

      describe "#set_user_attributes"  do
        subject { create(:user, name: "Bob") }

        it "sets only current_password" do
          subject.name.should eql "Bob"
          site = create(:site, user: subject, plan_id: @paid_plan.id)
          site.update_attributes(user_attributes: { name: "John", 'current_password' => '123456' })
          site.user.name.should eql "Bob"
          site.user.current_password.should eq "123456"
        end
      end

      describe "#set_default_dev_hostnames" do
        specify do
          subject.dev_hostnames.should be_nil
          subject.should be_valid
          subject.dev_hostnames.should eq Site::DEFAULT_DEV_DOMAINS
        end
      end

    end

    describe "before_save" do
      subject { create(:site_with_invoice, first_paid_plan_started_at: Time.now.utc) }

      pending "#prepare_pending_attributes" do
        context "when pending_plan_id has changed" do
          it "calls #prepare_pending_attributes" do
            subject.reload
            subject.plan_id = @paid_plan.id
            VCR.use_cassette('ogone/visa_payment_generic') { subject.skip_password(:save!) }
            subject.pending_plan_id.should eq @paid_plan.id
            subject.reload # apply_pending_attributes called
            subject.plan_id.should eq @paid_plan.id
            subject.pending_plan_id.should be_nil
          end
        end

        context "when pending_plan_id doesn't change" do
          it "doesn't call #prepare_pending_attributes" do
            subject.hostname = 'test.com'
            subject.skip_password(:save!)
            subject.pending_plan_id.should be_nil
          end
        end
      end
    end # before_save

    describe "after_create :delay_update_ranks" do
      it "delays update_ranks" do
        expect { create(:site) }.to change(Delayed::Job.where{ handler =~ "%update_ranks%" }, :count).by(1)
      end
    end

  end # Callbacks

  describe 'Class methods' do
    describe 'update_ranks' do
      use_vcr_cassette 'sites/ranks'

      context "site has a hostname" do
        it "updates ranks" do
          site = create(:fake_site, hostname: 'sublimevideo.net')
          Delayed::Job.delete_all

          described_class.send(:update_ranks, site.id)
          site.reload

          site.google_rank.should eq 6
          site.alexa_rank.should eq 91386
        end
      end

      context "site has blank hostname" do
        it "updates ranks" do
          site = create(:fake_site, hostname: '', plan_id: @free_plan.id)
          Delayed::Job.delete_all

          described_class.send(:update_ranks, site.id)
          site.reload

          site.google_rank.should eq 0
          site.alexa_rank.should eq 0
        end
      end
    end
  end

  describe 'Instance Methods' do

    pending "#skip_password" do
      subject { create(:site, hostname: "rymai.com") }

      it "should ask password when not calling this method" do
        subject.hostname.should eq "rymai.com"
        subject.hostname = "remy.com"
        subject.save
        subject.should_not be_valid
        subject.should have(1).error_on(:base)
      end

      it "should not ask password when calling this method" do
        subject.hostname.should eq "rymai.com"
        subject.hostname = "remy.com"
        subject.skip_password(:save!)
        subject.should have(0).error_on(:base)
        subject.reload.hostname.should eq "remy.com"
      end

      it "should return the result of the given method" do
        subject.skip_password(:hostname).should eq "rymai.com"
      end
    end

    describe "#hostname_with_path_needed & #need_path?" do
      context "with web.me.com hostname" do
        subject { build(:site, hostname: 'web.me.com') }
        its(:need_path?)                { should be_true }
        its(:hostname_with_path_needed) { should eq 'web.me.com' }
      end
      context "with homepage.mac.com, web.me.com extra hostnames" do
        subject { build(:site, extra_hostnames: 'homepage.mac.com, web.me.com') }
        its(:need_path?)                { should be_true }
        its(:hostname_with_path_needed) { should eq 'web.me.com' }
      end
      context "with web.me.com hostname & path" do
        subject { build(:site, hostname: 'web.me.com', path: 'users/thibaud') }
        its(:need_path?)                { should be_false }
        its(:hostname_with_path_needed) { should be_nil }
      end
      context "with nothing special" do
        subject { build(:site) }
        its(:need_path?)                { should be_false }
        its(:hostname_with_path_needed) { should be_nil }
      end
    end

    describe "#hostname_with_subdomain_needed & #need_subdomain?" do
      context "with tumblr.com hostname" do
        subject { build(:site, wildcard: true, hostname: 'tumblr.com') }
        its(:need_subdomain?)                { should be_true }
        its(:hostname_with_subdomain_needed) { should eq 'tumblr.com' }
      end
      context "with tumblr.com extra hostnames" do
        subject { build(:site, wildcard: true, extra_hostnames: 'web.mac.com, tumblr.com') }
        its(:need_subdomain?)                { should be_true }
        its(:hostname_with_subdomain_needed) { should eq 'tumblr.com' }
      end
      context "with wildcard only" do
        subject { build(:site, wildcard: true) }
        its(:need_subdomain?)                { should be_false }
        its(:hostname_with_subdomain_needed) { should be_nil }
      end
      context "without wildcard" do
        subject { build(:site, hostname: 'tumblr.com') }
        its(:need_subdomain?)                { should be_false }
        its(:hostname_with_subdomain_needed) { should be_nil }
      end
    end

  end # Instance Methods

end

# == Schema Information
#
# Table name: sites
#
#  addons_settings                           :hstore
#  alexa_rank                                :integer
#  archived_at                               :datetime
#  badged                                    :boolean
#  cdn_up_to_date                            :boolean          default(FALSE)
#  created_at                                :datetime         not null
#  dev_hostnames                             :text
#  extra_hostnames                           :text
#  first_billable_plays_at                   :datetime
#  first_paid_plan_started_at                :datetime
#  first_plan_upgrade_required_alert_sent_at :datetime
#  google_rank                               :integer
#  hostname                                  :string(255)
#  id                                        :integer          not null, primary key
#  last_30_days_billable_video_views_array   :text
#  last_30_days_dev_video_views              :integer          default(0)
#  last_30_days_embed_video_views            :integer          default(0)
#  last_30_days_extra_video_views            :integer          default(0)
#  last_30_days_invalid_video_views          :integer          default(0)
#  last_30_days_main_video_views             :integer          default(0)
#  last_30_days_video_tags                   :integer          default(0)
#  license                                   :string(255)
#  loader                                    :string(255)
#  next_cycle_plan_id                        :integer
#  overusage_notification_sent_at            :datetime
#  path                                      :string(255)
#  pending_plan_cycle_ended_at               :datetime
#  pending_plan_cycle_started_at             :datetime
#  pending_plan_id                           :integer
#  pending_plan_started_at                   :datetime
#  plan_cycle_ended_at                       :datetime
#  plan_cycle_started_at                     :datetime
#  plan_id                                   :integer
#  plan_started_at                           :datetime
#  player_mode                               :string(255)      default("stable")
#  refunded_at                               :datetime
#  settings_updated_at                       :datetime
#  state                                     :string(255)
#  token                                     :string(255)
#  trial_started_at                          :datetime
#  updated_at                                :datetime         not null
#  user_id                                   :integer
#  wildcard                                  :boolean
#
# Indexes
#
#  index_sites_on_created_at                        (created_at)
#  index_sites_on_hostname                          (hostname)
#  index_sites_on_last_30_days_dev_video_views      (last_30_days_dev_video_views)
#  index_sites_on_last_30_days_embed_video_views    (last_30_days_embed_video_views)
#  index_sites_on_last_30_days_extra_video_views    (last_30_days_extra_video_views)
#  index_sites_on_last_30_days_invalid_video_views  (last_30_days_invalid_video_views)
#  index_sites_on_last_30_days_main_video_views     (last_30_days_main_video_views)
#  index_sites_on_plan_id                           (plan_id)
#  index_sites_on_user_id                           (user_id)
#

