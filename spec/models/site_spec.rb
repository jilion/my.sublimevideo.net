# coding: utf-8
require 'spec_helper'

describe Site, :addons do

  context "Factory" do
    subject { create(:site) }

    its(:user)                             { should be_present }
    its(:hostname)                         { should =~ /jilion[0-9]+\.com/ }
    its(:dev_hostnames)                    { should eq '127.0.0.1,localhost' }
    its(:extra_hostnames)                  { should be_nil }
    its(:path)                             { should be_nil }
    its(:wildcard)                         { should be_false }
    its(:token)                            { should =~ /^[a-z0-9]{8}$/ }
    its(:player_mode)                      { should eq "stable" }
    its(:last_30_days_main_video_views)    { should eq 0 }
    its(:last_30_days_extra_video_views)   { should eq 0 }
    its(:last_30_days_dev_video_views)     { should eq 0 }
    its(:last_30_days_invalid_video_views) { should eq 0 }
    its(:last_30_days_embed_video_views)   { should eq 0 }

    it { should be_active } # initial state
    it { should be_valid }
  end

  describe "Associations" do
    let(:site) { create(:site) }

    it { should belong_to(:user) }
    it { should belong_to(:plan) }
    it { should have_many(:invoices) }

    it { should have_many(:billable_items) }
    it { should have_many(:app_designs).through(:billable_items) }
    it { should have_many(:addon_plans).through(:billable_items) }
    it { should have_many(:billable_item_activities) }
    it { should have_many(:kits) }
    it { should have_many(:components).through(:billable_items) }

    pending 'addons scopes' do
      before do
        create(:trial_addonship, site: site, addon: @logo_sublime_addon, trial_started_on: (30.days - 1.second).ago)
        create(:trial_addonship, site: site, addon: @logo_no_logo_addon, trial_started_on: (30.days + 1.second).ago)
        create(:trial_addonship, site: site, addon: @stats_standard_addon)
        create(:subscribed_addonship, site: site, addon: @support_vip_addon, trial_started_on: (30.days + 1.second).ago)
        create(:inactive_addonship, site: site, addon: @design1_western_addon)
      end

      describe 'active addons' do
        it { site.addons.active.should =~ [@logo_sublime_addon, @logo_no_logo_addon, @stats_standard_addon, @support_vip_addon] }
      end

      describe 'subscribed addons' do
        it { site.addons.subscribed.should =~ [@support_vip_addon] }
      end

      describe 'inactive addons' do
        it { site.addons.inactive.should =~ [@design1_western_addon] }
      end

      describe 'out_of_trial addons' do
        it { site.addons.out_of_trial.should =~ [@logo_no_logo_addon] }
      end
    end


    describe "last_invoice" do
      it "should return the last paid invoice" do
        invoice = create(:invoice, site: site)

        site.last_invoice.should eq site.invoices.last
        site.last_invoice.should eq invoice
      end
    end
  end

  describe "Validations" do
    [:hostname, :dev_hostnames, :extra_hostnames, :path, :wildcard, :badged].each do |attribute|
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
      subject { build(:site, hostname: nil, extra_hostnames: nil, dev_hostnames: nil) }
      it { should be_valid } # dev hostnames are set before validation
      it { should have(0).error_on(:base) }
    end

  end # Validations

  describe "Attributes Accessors" do
    %w[hostname extra_hostnames dev_hostnames].each do |attr|
      describe "#{attr}=" do
        it "calls Hostname.clean" do
          site = build_stubbed(:site)
          Hostname.should_receive(:clean).with("foo.com")

          site.send("#{attr}=", "foo.com")
        end
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

  describe "Versioning" do
    let(:site) { with_versioning { create(:site) } }

    it "works!" do
      with_versioning do
        old_hostname = site.hostname
        site.update_attributes(hostname: "bob.com")
        site.versions.last.reify.hostname.should eq old_hostname
      end
    end
  end # Versioning

  describe "Callbacks" do

    describe "before_validation" do
      let(:site) { build_stubbed(:site, hostname: nil, dev_hostnames: nil) }

      describe "set default hostname" do
        specify do
          site.hostname.should be_nil
          site.should be_valid
          site.hostname.should eq Site::DEFAULT_DOMAIN
        end
      end

      describe "set default dev hostnames" do
        specify do
          site.dev_hostnames.should be_nil
          site.should be_valid
          site.dev_hostnames.should eq Site::DEFAULT_DEV_DOMAINS
        end
      end
    end

    describe "before_save" do
      let(:site) { create(:site, first_paid_plan_started_at: Time.now.utc) }

      it "delays Service::Loader update on site player_mode update" do
        site = create(:site)
        -> { site.update_attribute(:player_mode, 'beta') }.should delay('%Service::Loader%update_all_modes%')
      end

      it "delays Service::Settings update on site player_mode update" do
        site = create(:site)
        -> { site.update_attribute(:player_mode, 'beta') }.should delay('%Service::Settings%update_all_types%')
      end

      it "touch settings_updated_at on site player_mode update" do
        site = create(:site)
        expect { site.update_attribute(:player_mode, 'beta') }.to change(site, :settings_updated_at)
      end
    end # before_save

    describe "after_create" do
      let(:site) { create(:site) }

      it "delays Service::Loader update" do
        -> { site }.should delay('%Service::Loader%update_all_modes%')
      end

      it "delays Service::Settings update" do
        -> { site }.should delay('%Service::Settings%update_all_types%')
      end
    end
  end # Callbacks

  describe "State Machine" do
    describe "after transition" do
      let(:site) { create(:site) }

      it "delays Service::Loader update" do
        site
        -> { site.update_attribute(:player_mode, 'beta') }.should delay('%Service::Loader%update_all_modes%')
        expect { site.suspend }.to change(Delayed::Job.where{ handler =~ "%Service::Loader%update_all_modes%" }, :count).by(1)
      end

      it "delays Service::Settings update" do
        site
        -> { site.update_attribute(:player_mode, 'beta') }.should delay('%Service::Loader%update_all_modes%')
        expect { site.suspend }.to change(Delayed::Job.where{ handler =~ "%Service::Settings%update_all_types%" }, :count).by(1)
      end
    end

    describe "before transition on archive" do
      let(:site) { create(:site) }

      it "set archived_at" do
        expect { site.archive! }.to change(site, :archived_at)
      end
    end

    describe "after transition on archive" do
      let(:site) { create(:site) }
      before do
        @open_invoice   = create(:invoice, site: site)
        @failed_invoice = create(:failed_invoice, site: site)
        @paid_invoice   = create(:paid_invoice, site: site)
      end

      it "cancels all not paid invoices" do
        site.archive!

        @open_invoice.reload.should be_canceled
        @failed_invoice.reload.should be_canceled
        @paid_invoice.reload.should be_paid
      end
    end
  end # State Machine

  describe '#trial_days_remaining_for_billable_item' do
    let(:addon_plan) { create(:addon_plan) }
    before do
      @billable_item_activity1 = create(:billable_item_activity, item: addon_plan, state: 'trial', created_at: 31.days.ago)
      @billable_item_activity2 = create(:billable_item_activity, item: addon_plan, state: 'trial', created_at: 30.days.ago)
      @billable_item_activity3 = create(:billable_item_activity, item: addon_plan, state: 'trial', created_at: 29.days.ago)
      @billable_item_activity4 = create(:billable_item_activity, item: addon_plan, state: 'trial', created_at: 28.days.ago)
      @billable_item_activity5 = create(:billable_item_activity, item: addon_plan, state: 'trial', created_at: 14.days.ago)
      @billable_item_activity6 = create(:billable_item_activity, item: addon_plan, state: 'trial')
    end

    it 'works' do
      @billable_item_activity1.site.trial_days_remaining_for_billable_item(addon_plan).should eq 0
      @billable_item_activity2.site.trial_days_remaining_for_billable_item(addon_plan).should eq 0
      @billable_item_activity3.site.trial_days_remaining_for_billable_item(addon_plan).should eq 1
      @billable_item_activity4.site.trial_days_remaining_for_billable_item(addon_plan).should eq 2
      @billable_item_activity5.site.trial_days_remaining_for_billable_item(addon_plan).should eq 16
      @billable_item_activity6.site.trial_days_remaining_for_billable_item(addon_plan).should eq 30
      create(:site).trial_days_remaining_for_billable_item(addon_plan).should be_nil
    end
  end

end

# == Schema Information
#
# Table name: sites
#
#  alexa_rank                                :integer
#  archived_at                               :datetime
#  badged                                    :boolean
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
#  loaders_updated_at                        :datetime
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

