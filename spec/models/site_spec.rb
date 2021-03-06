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
    its(:last_30_days_admin_starts)        { should eq 0 }
    its(:last_30_days_starts)              { should eq 0 }

    it { should be_active } # initial state
    it { should be_valid }
  end

  describe 'Associations' do
    let(:site) { create(:site) }

    it { should belong_to(:user) }
    it { should belong_to(:plan) }
    it { should belong_to(:default_kit) }
    it { should have_many(:invoices) }
    it { should have_one(:last_invoice) }

    it { should have_many(:billable_items) }
    it { should have_many(:designs).through(:billable_items) }
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
  end

  describe "Validations" do
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
        site.update(hostname: "bob.com")
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
          LoaderGenerator.should delay(:update_all_stages!, queue: 'my', at: 10.seconds.from_now.to_i).with(site.id, deletable: true)
          site.update(accessible_stage: 'alpha')
        end
      end

      it "delays SettingsGenerator update if accessible_stage changed" do
        Timecop.freeze do
          SettingsGenerator.should delay(:update_all!, queue: 'my', at: 10.seconds.from_now.to_i).with(site.id)
          site.update(accessible_stage: 'alpha')
        end
      end
    end
  end # Callbacks

  describe "State Machine" do
    let(:site) { create(:site) }

    describe "after transition" do
      it "delays LoaderGenerator update" do
        Timecop.freeze do
          LoaderGenerator.should delay(:update_all_stages!, queue: 'my', at: 10.seconds.from_now.to_i).with(site.id, deletable: true)
          site.suspend
        end
      end

      it "delays SettingsGenerator update" do
        Timecop.freeze do
          SettingsGenerator.should delay(:update_all!, queue: 'my', at: 10.seconds.from_now.to_i).with(site.id)
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

          site.reload.billable_items.should have(16).items
          site.billable_items.with_item(@classic_design)            .state('suspended').should have(1).item
          site.billable_items.with_item(@flat_design)               .state('suspended').should have(1).item
          site.billable_items.with_item(@light_design)              .state('suspended').should have(1).item
          site.billable_items.with_item(@video_player_addon_plan_1) .state('suspended').should have(1).item
          site.billable_items.with_item(@lightbox_addon_plan_1)     .state('suspended').should have(1).item
          site.billable_items.with_item(@image_viewer_addon_plan_1) .state('suspended').should have(1).item
          site.billable_items.with_item(@stats_addon_plan_1)        .state('suspended').should have(1).item
          site.billable_items.with_item(@logo_addon_plan_3)         .state('suspended').should have(1).item
          site.billable_items.with_item(@controls_addon_plan_1)     .state('suspended').should have(1).item
          site.billable_items.with_item(@initial_addon_plan_1)      .state('suspended').should have(1).item
          site.billable_items.with_item(@social_sharing_addon_plan_1).state('suspended').should have(1).item
          site.billable_items.with_item(@cuezones_addon_plan_1)     .state('suspended').should have(1).item
          site.billable_items.with_item(@google_analytics_addon_plan_1).state('suspended').should have(1).item
          site.billable_items.with_item(@embed_addon_plan_2)        .state('suspended').should have(1).item
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
          site.reload.billable_items.should have(16).items
          site.suspend!

          site.reload.billable_items.should have(16).items
          site.unsuspend!

          site.reload.billable_items.should have(16).items
          site.billable_items.with_item(@classic_design)            .state('subscribed').should have(1).item
          site.billable_items.with_item(@flat_design)               .state('subscribed').should have(1).item
          site.billable_items.with_item(@light_design)              .state('subscribed').should have(1).item
          site.billable_items.with_item(@video_player_addon_plan_1) .state('subscribed').should have(1).item
          site.billable_items.with_item(@lightbox_addon_plan_1)     .state('subscribed').should have(1).item
          site.billable_items.with_item(@image_viewer_addon_plan_1) .state('subscribed').should have(1).item
          site.billable_items.with_item(@stats_addon_plan_1)        .state('subscribed').should have(1).item
          site.billable_items.with_item(@logo_addon_plan_3)         .state('sponsored').should have(1).item
          site.billable_items.with_item(@controls_addon_plan_1)     .state('subscribed').should have(1).item
          site.billable_items.with_item(@initial_addon_plan_1)      .state('subscribed').should have(1).item
          site.billable_items.with_item(@social_sharing_addon_plan_1).state('sponsored').should have(1).item
          site.billable_items.with_item(@cuezones_addon_plan_1)     .state('sponsored').should have(1).item
          site.billable_items.with_item(@google_analytics_addon_plan_1).state('sponsored').should have(1).item
          site.billable_items.with_item(@embed_addon_plan_2)        .state('sponsored').should have(1).item
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
          site.reload.billable_items.should have(16).items
          site.billable_items.with_item(@logo_addon_plan_2).state('trial').should have(1).item

          site.suspend!

          site.reload.billable_items.with_item(@logo_addon_plan_2).state('suspended').should have(1).item

          site.unsuspend!

          site.reload.billable_items.should have(16).items
          site.billable_items.with_item(@classic_design)            .state('subscribed').should have(1).item
          site.billable_items.with_item(@flat_design)               .state('subscribed').should have(1).item
          site.billable_items.with_item(@light_design)              .state('subscribed').should have(1).item
          site.billable_items.with_item(@video_player_addon_plan_1) .state('subscribed').should have(1).item
          site.billable_items.with_item(@lightbox_addon_plan_1)     .state('subscribed').should have(1).item
          site.billable_items.with_item(@image_viewer_addon_plan_1) .state('subscribed').should have(1).item
          site.billable_items.with_item(@stats_addon_plan_1)        .state('subscribed').should have(1).item
          site.billable_items.with_item(@logo_addon_plan_2)         .state('sponsored').should have(1).item
          site.billable_items.with_item(@controls_addon_plan_1)     .state('subscribed').should have(1).item
          site.billable_items.with_item(@initial_addon_plan_1)      .state('subscribed').should have(1).item
          site.billable_items.with_item(@social_sharing_addon_plan_1).state('sponsored').should have(1).item
          site.billable_items.with_item(@cuezones_addon_plan_1)     .state('sponsored').should have(1).item
          site.billable_items.with_item(@google_analytics_addon_plan_1).state('sponsored').should have(1).item
          site.billable_items.with_item(@embed_addon_plan_2)        .state('sponsored').should have(1).item
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
        specify { Site.active.should =~ [@site_active] }
      end

      describe ".suspended" do
        specify { Site.suspended.should =~ [@site_suspended] }
      end

      describe ".archived" do
        specify { Site.archived.should =~ [@site_archived] }
      end

      describe ".not_archived" do
        specify { Site.not_archived.should =~ [@site_active, @site_suspended] }
      end
    end

    describe "attributes queries" do
      before do
        @site_wildcard        = create(:site, hostname: 'google.com', user: user, wildcard: true)
        @site_path            = create(:site, hostname: 'facebook.com', user: user, path: "foo", path: 'foo')
        @site_extra_hostnames = create(:site, user: user, extra_hostnames: "foo.com")
        @site_next_cycle_plan = create(:site, user: user, created_at: 3.days.from_now)
      end

      describe ".without_hostnames" do
        specify { Site.without_hostnames(%w[google.com facebook.com]).should =~ [@site_extra_hostnames, @site_next_cycle_plan] }
      end

      describe ".with_wildcard" do
        specify { Site.with_wildcard.should =~ [@site_wildcard] }
      end

      describe ".with_path" do
        specify { Site.with_path.should =~ [@site_path] }
      end

      describe ".with_extra_hostnames" do
        specify { Site.with_extra_hostnames.should =~ [@site_extra_hostnames] }
      end

      describe '.created_on' do
        specify { Site.created_on(3.days.from_now).should =~ [@site_next_cycle_plan] }
      end

      describe '.created_after' do
        specify { Site.created_after(2.days.from_now).should =~ [@site_next_cycle_plan] }
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
        it { Site.paying.should =~ [site1] }
      end

      describe '.free' do
        it { Site.free.should =~ [site2] }
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
        specify { Site.with_not_canceled_invoices.should =~ [@site_with_paid_invoice] }
      end
    end

    describe ".created_between" do
      before do
        @site1 = create(:site, created_at: 3.days.ago)
        @site2 = create(:site, created_at: 2.days.ago)
        @site3 = create(:site, created_at: 1.days.ago)
      end

      specify { Site.where(created_at: 3.days.ago.midnight..2.days.ago.end_of_day).should =~ [@site1, @site2] }
      specify { Site.where(created_at: 2.days.ago.end_of_day..1.day.ago.end_of_day).should =~ [@site3] }
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
#  accessible_stage          :string(255)      default("beta")
#  addons_updated_at         :datetime
#  alexa_rank                :integer
#  archived_at               :datetime
#  badged                    :boolean
#  created_at                :datetime
#  current_assistant_step    :string(255)
#  default_kit_id            :integer
#  dev_hostnames             :text
#  extra_hostnames           :text
#  first_admin_starts_on     :datetime
#  google_rank               :integer
#  hostname                  :string(255)
#  id                        :integer          not null, primary key
#  last_30_days_admin_starts :integer          default(0)
#  last_30_days_starts       :integer          default(0)
#  last_30_days_starts_array :integer          default([])
#  last_30_days_video_tags   :integer          default(0)
#  loaders_updated_at        :datetime
#  path                      :string(255)
#  plan_id                   :integer
#  refunded_at               :datetime
#  settings_updated_at       :datetime
#  staging_hostnames         :text
#  state                     :string(255)
#  token                     :string(255)
#  updated_at                :datetime
#  user_id                   :integer
#  wildcard                  :boolean
#
# Indexes
#
#  index_sites_on_created_at                       (created_at)
#  index_sites_on_id_and_state                     (id,state)
#  index_sites_on_last_30_days_admin_starts        (last_30_days_admin_starts)
#  index_sites_on_plan_id                          (plan_id)
#  index_sites_on_token                            (token)
#  index_sites_on_user_id                          (user_id)
#  index_sites_on_user_id_and_last_30_days_starts  (user_id,last_30_days_starts)
#

