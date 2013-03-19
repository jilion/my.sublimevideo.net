# coding: utf-8
require 'spec_helper'

describe Site, :addons do
  context "Factory" do
    subject { create(:site) }

    its(:user)                             { should be_present }
    its(:hostname)                         { should =~ /jilion[0-9]+\.com/ }
    its(:dev_hostnames)                    { should eq '127.0.0.1, localhost' }
    its(:extra_hostnames)                  { should be_nil }
    its(:path)                             { should be_nil }
    its(:wildcard)                         { should be_false }
    its(:token)                            { should =~ /^[a-z0-9]{8}$/ }
    its(:accessible_stage)                 { should eq "beta" }
    its(:last_30_days_main_video_views)    { should eq 0 }
    its(:last_30_days_extra_video_views)   { should eq 0 }
    its(:last_30_days_dev_video_views)     { should eq 0 }
    its(:last_30_days_invalid_video_views) { should eq 0 }
    its(:last_30_days_embed_video_views)   { should eq 0 }

    it { should be_active } # initial state
    it { should be_valid }
  end

  describe "API" do
    describe "#to_api" do
      context "normal site" do
        let(:site)     { create(:site, hostname: 'rymai.me', dev_hostnames: 'rymai.local', extra_hostnames: 'rymai.com', staging_hostnames: 'rymai-staging.com', wildcard: true, path: 'test', accessible_stage: 'alpha') }
        let(:response) { site.as_api_response(:v1_self_private) }

        it "selects a subset of fields, as a hash" do
          response.should be_a(Hash)
          response[:token].should eq site.token
          response[:main_domain].should eq 'rymai.me'
          response[:extra_domains].should eq ['rymai.com']
          response[:staging_domains].should eq ['rymai-staging.com']
          response[:dev_domains].should eq ['rymai.local']
          response[:wildcard].should eq true
          response[:path].should eq 'test'
          response[:accessible_stage].should eq 'alpha'
        end
      end

      context "site without optional fields" do
        let(:site) {
          site = create(:site, hostname: 'rymai.me', extra_hostnames: nil, wildcard: false, path: nil)
          site.update_attribute(:dev_hostnames, nil)
          site
        }
        let(:response) { site.as_api_response(:v1_self_private) }

        it "selects a subset of fields, as a hash" do
          response.should be_a(Hash)
          response[:token].should eq site.token
          response[:main_domain].should eq 'rymai.me'
          response[:extra_domains].should eq []
          response[:staging_domains].should eq []
          response[:extra_domains].should eq []
          response[:wildcard].should eq false
          response[:path].should eq ''
        end
      end
    end

    describe "#usage_to_api" do
      context "with no usage" do
        let(:site)     { create(:site, hostname: 'rymai.me', dev_hostnames: 'rymai.local', extra_hostnames: 'rymai.com', wildcard: true, path: 'test') }
        let(:response) { site.as_api_response(:v1_usage_private) }

        before do
          create(:site_usage, site_id: site.id, day: 61.days.ago.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400)
          create(:site_usage, site_id: site.id, day: 59.days.ago.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400)
          create(:site_usage, site_id: site.id, day: Time.now.utc.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400)
        end

        it "selects a subset of fields, as a hash" do
          response.should be_a(Hash)
          response[:token].should eq site.token
          response[:usage].should eq site.usages.between(day: 60.days.ago.midnight..Time.now.utc.end_of_day).as_api_response(:v1_self_private)
        end
      end
    end
  end

  describe 'Associations' do
    let(:site) { create(:site) }

    it { should belong_to(:user) }
    it { should belong_to(:plan) }
    it { should belong_to(:default_kit) }
    it { should have_many(:invoices) }
    it { should have_one(:last_invoice) }

    it { should have_many(:billable_items) }
    it { should have_many(:app_designs).through(:billable_items) }
    it { should have_many(:addon_plans).through(:billable_items) }
    it { should have_many(:addons).through(:addon_plans) }
    it { should have_many(:plugins).through(:addons) }
    it { should have_many(:billable_item_activities) }
    it { should have_many(:kits) }

    describe "last_invoice" do
      it "should return the last paid invoice" do
        invoice = create(:invoice, site: site)

        site.last_invoice.should eq site.invoices.last
        site.last_invoice.should eq invoice
      end
    end

    describe "components" do
      # it "returns components from AddonPlan && App::Design" do
      it "returns components from App::Design" do
        site = create(:site)
        app_design = create(:app_design)
        create(:billable_item, site: site, item: app_design)
        app_custom_design = create(:app_design)

        # addon = create(:addon)
        # addon_plan = create(:addon_plan, addon: addon)
        # app_plugin_with_design = create(:app_plugin, addon: addon, design: app_design)
        # app_plugin_without_design = create(:app_plugin, addon: addon, design: nil)
        # app_plugin_without_custom_design = create(:app_plugin, addon: addon, design: app_custom_design)
        # create(:billable_item, site: site, item: addon_plan)

        site.components.should match_array([
          app_design.component,
          # app_plugin_with_design.component,
          # app_plugin_without_design.component
        ])
      end
    end
  end

  describe "Validations" do
    [:hostname, :dev_hostnames, :staging_hostnames, :extra_hostnames, :path, :wildcard].each do |attribute|
      it { should allow_mass_assignment_of(attribute) }
    end

    it { should validate_presence_of(:user) }
    it { should ensure_length_of(:path).is_at_most(255) }

    it { should allow_value('alpha').for(:accessible_stage) }
    it { should allow_value('beta').for(:accessible_stage) }
    it { should allow_value('stable').for(:accessible_stage) }
    it { should_not allow_value('dev').for(:accessible_stage) }
    it { should_not allow_value('fake').for(:accessible_stage) }

    specify { Site.validators_on(:hostname).map(&:class).should eq [HostnameValidator] }
    specify { Site.validators_on(:extra_hostnames).map(&:class).should include ExtraHostnamesValidator }
    specify { Site.validators_on(:staging_hostnames).map(&:class).should include ExtraHostnamesValidator }
    specify { Site.validators_on(:dev_hostnames).map(&:class).should include DevHostnamesValidator }

    describe "with no hostnames at all" do
      subject { build(:site, hostname: nil, extra_hostnames: nil, staging_hostnames: nil, dev_hostnames: nil) }
      it { should be_valid } # dev hostnames are set before validation
      it { should have(0).error_on(:base) }

      context "after validation" do
        before { subject.valid? }
        its(:hostname) { should == Site::DEFAULT_DOMAIN }
        its(:dev_hostnames) { should == Site::DEFAULT_DEV_DOMAINS }
      end
    end

    describe "with blank hostnames" do
      subject { build(:site, hostname: "", extra_hostnames: "", dev_hostnames: "") }
      it { should be_valid } # dev hostnames are set before validation
      it { should have(0).error_on(:base) }

      context "after validation" do
        before { subject.valid? }
        its(:hostname) { should == Site::DEFAULT_DOMAIN }
        its(:dev_hostnames) { should == Site::DEFAULT_DEV_DOMAINS }
      end
    end
  end # Validations

  describe "Attributes Accessors" do
    %w[hostname extra_hostnames staging_hostnames dev_hostnames].each do |attr|
      describe "#{attr}=" do
        it "calls HostnameHandler.clean" do
          site = build_stubbed(:site)
          HostnameHandler.should_receive(:clean).with("foo.com")

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
      old_hostname = site.hostname
      with_versioning do
        site.update_attributes(hostname: "bob.com")
      end
      site.versions.last.reify.hostname.should eq old_hostname
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

    describe "after_save" do
      let(:site) { create(:site) }

      it "delays LoaderGenerator update if accessible_stage changed" do
        Timecop.freeze do
          LoaderGenerator.should delay(:update_all_stages!, at: 5.seconds.from_now.to_i).with(site.id, deletable: true)
          site.update_attributes({ accessible_stage: 'alpha' }, without_protection: true)
        end
      end

      it "delays SettingsGenerator update if accessible_stage changed" do
        Timecop.freeze do
          SettingsGenerator.should delay(:update_all!, at: 5.seconds.from_now.to_i).with(site.id)
          site.update_attributes({ accessible_stage: 'alpha' }, without_protection: true)
        end
      end
    end
  end # Callbacks

  describe "State Machine" do
    let(:site) { create(:site) }
    let(:plus_plan) { create(:plan, name: 'plus') }
    let(:premium_plan) { create(:plan, name: 'premium') }

    describe "after transition" do
      it "delays LoaderGenerator update" do
        Timecop.freeze do
          LoaderGenerator.should delay(:update_all_stages!, at: 5.seconds.from_now.to_i).with(site.id, deletable: true)
          site.suspend
        end
      end

      it "delays SettingsGenerator update" do
        Timecop.freeze do
          SettingsGenerator.should delay(:update_all!, at: 5.seconds.from_now.to_i).with(site.id)
          site.suspend
        end
      end
    end

    describe "before transition on suspend", :addons do
      context 'with billable items' do
        let(:site) do
          site = build(:site)
          SiteManager.new(site).create
          site
        end

        it 'suspends all billable items' do
          site.suspend!

          site.reload.billable_items.should have(13).items
          site.billable_items.with_item(@classic_design)            .state('suspended').should have(1).item
          site.billable_items.with_item(@flat_design)               .state('suspended').should have(1).item
          site.billable_items.with_item(@light_design)              .state('suspended').should have(1).item
          site.billable_items.with_item(@video_player_addon_plan_1) .state('suspended').should have(1).item
          site.billable_items.with_item(@lightbox_addon_plan_1)     .state('suspended').should have(1).item
          site.billable_items.with_item(@image_viewer_addon_plan_1) .state('suspended').should have(1).item
          site.billable_items.with_item(@stats_addon_plan_1)        .state('suspended').should have(1).item
          site.billable_items.with_item(@logo_addon_plan_1)         .state('suspended').should have(1).item
          site.billable_items.with_item(@controls_addon_plan_1)     .state('suspended').should have(1).item
          site.billable_items.with_item(@initial_addon_plan_1)      .state('suspended').should have(1).item
          site.billable_items.with_item(@embed_addon_plan_1)        .state('suspended').should have(1).item
          site.billable_items.with_item(@api_addon_plan_1)          .state('suspended').should have(1).item
          site.billable_items.with_item(@support_addon_plan_1)      .state('suspended').should have(1).item
        end

        it "increments metrics" do
          Librato.stub(:increment)
          Librato.should_receive(:increment).with('sites.events', source: 'suspend')
          site.suspend!
        end
      end
    end

    describe "before transition on unsuspend", :addons do
      context 'with billable items' do
        let(:site) do
          site = build(:site)
          SiteManager.new(site).create
          site
        end

        it 'unsuspend all billable items' do
          site.reload.billable_items.should have(13).items
          site.suspend!

          site.reload.billable_items.should have(13).items
          site.unsuspend!

          site.reload.billable_items.should have(13).items
          site.billable_items.with_item(@classic_design)            .state('subscribed').should have(1).item
          site.billable_items.with_item(@flat_design)               .state('subscribed').should have(1).item
          site.billable_items.with_item(@light_design)              .state('subscribed').should have(1).item
          site.billable_items.with_item(@video_player_addon_plan_1) .state('subscribed').should have(1).item
          site.billable_items.with_item(@lightbox_addon_plan_1)     .state('subscribed').should have(1).item
          site.billable_items.with_item(@image_viewer_addon_plan_1) .state('subscribed').should have(1).item
          site.billable_items.with_item(@stats_addon_plan_1)        .state('subscribed').should have(1).item
          site.billable_items.with_item(@logo_addon_plan_1)         .state('subscribed').should have(1).item
          site.billable_items.with_item(@controls_addon_plan_1)     .state('subscribed').should have(1).item
          site.billable_items.with_item(@initial_addon_plan_1)      .state('subscribed').should have(1).item
          site.billable_items.with_item(@embed_addon_plan_1)        .state('subscribed').should have(1).item
          site.billable_items.with_item(@api_addon_plan_1)          .state('subscribed').should have(1).item
          site.billable_items.with_item(@support_addon_plan_1)      .state('subscribed').should have(1).item
        end
      end

      context 'with a billable item in trial' do
        let(:site) do
          site = build(:site)
          SiteManager.new(site).tap do |service|
            service.create
            service.update_billable_items({}, { logo: AddonPlan.get('logo', 'disabled').id })
          end
          site
        end

        it 'unsuspend all billable items' do
          site.reload.billable_items.should have(13).items
          site.billable_items.with_item(@logo_addon_plan_2).state('trial').should have(1).item

          site.suspend!

          site.reload.billable_items.with_item(@logo_addon_plan_2).state('suspended').should have(1).item

          site.unsuspend!

          site.reload.billable_items.should have(13).items
          site.billable_items.with_item(@classic_design)            .state('subscribed').should have(1).item
          site.billable_items.with_item(@flat_design)               .state('subscribed').should have(1).item
          site.billable_items.with_item(@light_design)              .state('subscribed').should have(1).item
          site.billable_items.with_item(@video_player_addon_plan_1) .state('subscribed').should have(1).item
          site.billable_items.with_item(@lightbox_addon_plan_1)     .state('subscribed').should have(1).item
          site.billable_items.with_item(@image_viewer_addon_plan_1) .state('subscribed').should have(1).item
          site.billable_items.with_item(@stats_addon_plan_1)        .state('subscribed').should have(1).item
          site.billable_items.with_item(@logo_addon_plan_2)         .state('trial').should have(1).item
          site.billable_items.with_item(@controls_addon_plan_1)     .state('subscribed').should have(1).item
          site.billable_items.with_item(@initial_addon_plan_1)      .state('subscribed').should have(1).item
          site.billable_items.with_item(@embed_addon_plan_1)        .state('subscribed').should have(1).item
          site.billable_items.with_item(@api_addon_plan_1)          .state('subscribed').should have(1).item
          site.billable_items.with_item(@support_addon_plan_1)      .state('subscribed').should have(1).item
        end
      end
    end

    describe "before transition on archive" do
      it "set archived_at" do
        expect { site.archive! }.to change(site, :archived_at)
      end

      it "clear all billable items" do
        site.archive!
        site.billable_items.should be_empty
      end

      it "increments metrics" do
        Librato.should_receive(:increment).with('sites.events', source: 'archive')
        site.archive!
      end

      context "with non-paid invoices" do
        before do
          @open_invoice   = create(:invoice, site: site)
          @failed_invoice = create(:failed_invoice, site: site)
          @paid_invoice   = create(:paid_invoice, site: site)
        end

        it "raises an exception" do
          expect { site.archive! }.to raise_error(ActiveRecord::ActiveRecordError)

          @open_invoice.reload.should be_open
          @failed_invoice.reload.should be_failed
          @paid_invoice.reload.should be_paid
        end
      end
    end
  end # State Machine

  describe "Scopes" do
    let(:user) { create(:user) }

    describe "state" do
      before do
        @site_active    = create(:site, user: user)
        @site_archived  = create(:site, user: user, state: "archived", archived_at: Time.utc(2010,2,28))
        @site_suspended = create(:site, user: user, state: "suspended")
      end

      describe ".active" do
        specify { Site.active.all.should =~ [@site_active] }
      end

      describe ".inactive" do
        specify { Site.inactive.all.should =~ [@site_archived, @site_suspended] }
      end

      describe ".suspended" do
        specify { Site.suspended.all.should =~ [@site_suspended] }
      end

      describe ".archived" do
        specify { Site.archived.all.should =~ [@site_archived] }
      end

      describe ".not_archived" do
        specify { Site.not_archived.all.should =~ [@site_active, @site_suspended] }
      end
    end

    describe "attributes queries" do
      before do
        @site_wildcard        = create(:site, user: user, wildcard: true)
        @site_path            = create(:site, user: user, path: "foo", path: 'foo')
        @site_extra_hostnames = create(:site, user: user, extra_hostnames: "foo.com")
        @site_next_cycle_plan = create(:site, user: user)
      end

      describe ".with_wildcard" do
        specify { Site.with_wildcard.all.should =~ [@site_wildcard] }
      end

      describe ".with_path" do
        specify { Site.with_path.all.should =~ [@site_path] }
      end

      describe ".with_extra_hostnames" do
        specify { Site.with_extra_hostnames.all.should =~ [@site_extra_hostnames] }
      end
    end

    describe "addons", :addons do
      let(:site1) { create(:site, user: user) }
      let(:site2) { create(:site, user: user) }
      let(:site3) { create(:site, user: user, state: 'archived') }
      before do
        Timecop.travel(31.days.ago) do
          create(:billable_item, site: site1, item: @social_sharing_addon_plan_1, state: 'beta')
          create(:billable_item_activity, site: site1, item: @social_sharing_addon_plan_1, state: 'beta')

          create(:billable_item, site: site2, item: @logo_addon_plan_2, state: 'trial')

          create(:billable_item, site: site3, item: @social_sharing_addon_plan_1, state: 'beta')
          create(:billable_item_activity, site: site3, item: @social_sharing_addon_plan_1, state: 'beta')
        end
        Timecop.travel(30.days.ago) do
          create(:billable_item, site: site2, item: @logo_addon_plan_1, state: 'trial')
          create(:billable_item_activity, site: site2, item: @logo_addon_plan_1, state: 'trial')
        end
        create(:billable_item, site: site2, item: @stats_addon_plan_1, state: 'trial')
        create(:billable_item_activity, site: site2, item: @stats_addon_plan_1, state: 'trial')

        create(:billable_item, site: site1, item: @support_addon_plan_2, state: 'subscribed')
        create(:billable_item_activity, site: site1, item: @support_addon_plan_2, state: 'subscribed')

        create(:billable_item, site: site3, item: @support_addon_plan_2, state: 'subscribed')
        create(:billable_item_activity, site: site3, item: @support_addon_plan_2, state: 'subscribed')
      end

      describe '.paying' do
        it { Site.paying.all.should =~ [site1] }
      end

      describe '.free' do
        it { Site.free.all.should =~ [site2] }
      end

      describe '.in_beta_trial_ended_after' do
        it { Site.in_beta_trial_ended_after('social_sharing-standard', Time.now.utc).all.should =~ [site1] }
      end
    end

    describe "invoices" do
      before do
        @site_with_no_invoice       = create(:site, user: user)
        @site_with_paid_invoice     = create(:site, user: user)
        @site_with_canceled_invoice = create(:site, user: user)

        create(:invoice, site: @site_with_paid_invoice)
        create(:canceled_invoice, site: @site_with_canceled_invoice)
      end

      describe ".with_not_canceled_invoices" do
        specify { Site.with_not_canceled_invoices.all.should =~ [@site_with_paid_invoice] }
      end
    end

    describe ".created_between" do
      before do
        @site1 = create(:site, created_at: 3.days.ago)
        @site2 = create(:site, created_at: 2.days.ago)
        @site3 = create(:site, created_at: 1.days.ago)
      end

      specify { Site.between(created_at: 3.days.ago.midnight..2.days.ago.end_of_day).all.should =~ [@site1, @site2] }
      specify { Site.between(created_at: 2.days.ago.end_of_day..1.day.ago.end_of_day).all.should =~ [@site3] }
    end

    describe '.with_page_loads_in_the_last_30_days' do
      let(:site1) { create(:site) }
      let(:site2) { create(:site) }
      let(:site3) { create(:site) }
      let(:site4) { create(:site) }
      before do
        create(:site_day_stat, t: site1.token, d: 3.days.ago.midnight, pv: { m: 1 })
        create(:site_day_stat, t: site2.token, d: 1.day.ago.midnight, pv: { e: 1 })
        create(:site_day_stat, t: site3.token, d: 31.days.ago.utc.midnight, pv: { em: 1 })
        create(:site_day_stat, t: site4.token, d: Time.now.utc.midnight, vv: { em: 1 })
      end

      specify { Site.with_page_loads_in_the_last_30_days.all.should =~ [site1, site2] }
    end

    describe '.search' do
      let(:site) { create(:site) }

      specify { described_class.search(site.token).should eq [site] }
      specify { described_class.search(site.hostname).should eq [site] }
      specify { described_class.search(site.extra_hostnames).should eq [site] }
      specify { described_class.search(site.staging_hostnames).should eq [site] }
      specify { described_class.search(site.dev_hostnames).should eq [site] }
      specify { described_class.search(site.user.email).should eq [site] }
      specify { described_class.search(site.user.name).should eq [site] }
    end

  end # Scopes

end

# == Schema Information
#
# Table name: sites
#
#  accessible_stage                          :string(255)      default("beta")
#  addons_updated_at                         :datetime
#  alexa_rank                                :integer
#  archived_at                               :datetime
#  badged                                    :boolean
#  created_at                                :datetime         not null
#  current_assistant_step                    :string(255)
#  default_kit_id                            :integer
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
#  refunded_at                               :datetime
#  settings_updated_at                       :datetime
#  staging_hostnames                         :text
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
#  index_sites_on_token                             (token)
#  index_sites_on_user_id                           (user_id)
#

