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

  describe 'Associations' do
    let(:site) { create(:site) }

    it { should belong_to(:user) }
    it { should belong_to(:plan) }
    it { should belong_to(:default_kit) }
    it { should have_many(:invoices) }
    it { should have_one(:last_invoice) }
    it { should have_many :video_tags }

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

    describe "after_commit" do
      let(:site) { create(:site) }

      it "delays Service::Loader update if accessible_stage changed" do
        Timecop.freeze do
          Service::Loader.should delay(:update_all_stages!, at: 5.seconds.from_now.to_i).with(site.id)
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
      it "delays Service::Loader update" do
        Timecop.freeze do
          Service::Loader.should delay(:update_all_stages!, at: 5.seconds.from_now.to_i).with(site.id)
          site.suspend
        end
      end

      it "delays Service::Settings update" do
        Timecop.freeze do
          Service::Settings.should delay(:update_all_types!, at: 5.seconds.from_now.to_i).with(site.id)
          site.suspend
        end
      end
    end

    describe "before transition on suspend", :addons do
      context 'with plus plan' do
        let(:site) { create(:site, plan_id: plus_plan.id) }
        before do
          Service::Site.new(site).migrate_plan_to_addons!(AddonPlan.free_addon_plans, AddonPlan.free_addon_plans(reject: %w[logo stats support]))
          site.reload.billable_items.should have(13).items
        end

        it 'suspends all billable items' do
          site.suspend!

          site.reload.billable_items.should have(13).items
          site.billable_items.app_designs.where(item_id: @classic_design).where(state: 'suspended').should have(1).item
          site.billable_items.app_designs.where(item_id: @flat_design).where(state: 'suspended').should have(1).item
          site.billable_items.app_designs.where(item_id: @light_design).where(state: 'suspended').should have(1).item
          site.billable_items.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'suspended').should have(1).item
          site.billable_items.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'suspended').should have(1).item
          site.billable_items.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'suspended').should have(1).item
          site.billable_items.addon_plans.where(item_id: @stats_addon_plan_2).where(state: 'suspended').should have(1).item
          site.billable_items.addon_plans.where(item_id: @logo_addon_plan_2).where(state: 'suspended').should have(1).item
          site.billable_items.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'suspended').should have(1).item
          site.billable_items.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'suspended').should have(1).item
          site.billable_items.addon_plans.where(item_id: @sharing_addon_plan_1).where(state: 'suspended').should have(1).item
          site.billable_items.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'suspended').should have(1).item
          site.billable_items.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'suspended').should have(1).item
        end
      end

      context 'with premium plan' do
        let(:site) { create(:site, plan_id: premium_plan.id) }
        before do
          Service::Site.new(site).migrate_plan_to_addons!(AddonPlan.free_addon_plans, AddonPlan.free_addon_plans(reject: %w[logo stats support]))
          site.reload.billable_items.should have(13).items
        end

        it 'suspends all billable items' do
          site.suspend!

          site.reload.billable_items.should have(13).items
          site.billable_items.app_designs.where(item_id: @classic_design).where(state: 'suspended').should have(1).item
          site.billable_items.app_designs.where(item_id: @flat_design).where(state: 'suspended').should have(1).item
          site.billable_items.app_designs.where(item_id: @light_design).where(state: 'suspended').should have(1).item
          site.billable_items.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'suspended').should have(1).item
          site.billable_items.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'suspended').should have(1).item
          site.billable_items.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'suspended').should have(1).item
          site.billable_items.addon_plans.where(item_id: @stats_addon_plan_2).where(state: 'suspended').should have(1).item
          site.billable_items.addon_plans.where(item_id: @logo_addon_plan_2).where(state: 'suspended').should have(1).item
          site.billable_items.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'suspended').should have(1).item
          site.billable_items.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'suspended').should have(1).item
          site.billable_items.addon_plans.where(item_id: @sharing_addon_plan_1).where(state: 'suspended').should have(1).item
          site.billable_items.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'suspended').should have(1).item
          site.billable_items.addon_plans.where(item_id: @support_addon_plan_2).where(state: 'suspended').should have(1).item
        end
      end
    end

    describe "before transition on unsuspend", :addons do
      context 'with plus plan' do
        let(:site) { create(:site, plan_id: plus_plan.id) }
        before do
          Service::Site.new(site).migrate_plan_to_addons!(AddonPlan.free_addon_plans, AddonPlan.free_addon_plans(reject: %w[logo stats support]))
          site.reload.billable_items.should have(13).items
        end

        it 'suspends all billable items' do
          site.suspend!

          site.reload.billable_items.should have(13).items
          site.unsuspend!

          site.reload.billable_items.should have(13).items
          site.billable_items.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
          site.billable_items.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
          site.billable_items.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
          site.billable_items.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'beta').should have(1).item
          site.billable_items.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
          site.billable_items.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'beta').should have(1).item
          site.billable_items.addon_plans.where(item_id: @stats_addon_plan_2).where(state: 'sponsored').should have(1).item
          site.billable_items.addon_plans.where(item_id: @logo_addon_plan_2).where(state: 'subscribed').should have(1).item
          site.billable_items.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'beta').should have(1).item
          site.billable_items.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'beta').should have(1).item
          site.billable_items.addon_plans.where(item_id: @sharing_addon_plan_1).where(state: 'beta').should have(1).item
          site.billable_items.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
          site.billable_items.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item
        end
      end

      context 'with premium plan' do
        let(:site) { create(:site, plan_id: premium_plan.id) }
        before do
          Service::Site.new(site).migrate_plan_to_addons!(AddonPlan.free_addon_plans, AddonPlan.free_addon_plans(reject: %w[logo stats support]))
          site.reload.billable_items.should have(13).items
        end

        it 'suspends all billable items' do
          site.suspend!

          site.reload.billable_items.should have(13).items
          site.unsuspend!

          site.reload.billable_items.should have(13).items
          site.billable_items.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
          site.billable_items.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
          site.billable_items.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
          site.billable_items.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'beta').should have(1).item
          site.billable_items.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
          site.billable_items.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'beta').should have(1).item
          site.billable_items.addon_plans.where(item_id: @stats_addon_plan_2).where(state: 'subscribed').should have(1).item
          site.billable_items.addon_plans.where(item_id: @logo_addon_plan_2).where(state: 'subscribed').should have(1).item
          site.billable_items.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'beta').should have(1).item
          site.billable_items.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'beta').should have(1).item
          site.billable_items.addon_plans.where(item_id: @sharing_addon_plan_1).where(state: 'beta').should have(1).item
          site.billable_items.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
          site.billable_items.addon_plans.where(item_id: @support_addon_plan_2).where(state: 'sponsored').should have(1).item
        end
      end

      context 'without plan' do
        let(:site) do
          site = build(:site)
          Service::Site.new(site).create
          site
        end

        it 'unsuspend all billable items' do
          site.reload.billable_items.should have(13).items
          site.suspend!

          site.reload.billable_items.should have(13).items
          site.unsuspend!

          site.reload.billable_items.should have(13).items
          site.billable_items.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
          site.billable_items.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
          site.billable_items.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
          site.billable_items.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'beta').should have(1).item
          site.billable_items.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
          site.billable_items.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'beta').should have(1).item
          site.billable_items.addon_plans.where(item_id: @stats_addon_plan_1).where(state: 'subscribed').should have(1).item
          site.billable_items.addon_plans.where(item_id: @logo_addon_plan_1).where(state: 'subscribed').should have(1).item
          site.billable_items.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'beta').should have(1).item
          site.billable_items.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'beta').should have(1).item
          site.billable_items.addon_plans.where(item_id: @sharing_addon_plan_1).where(state: 'beta').should have(1).item
          site.billable_items.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
          site.billable_items.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item
        end
      end

      context 'with a billable item in trial plan' do
        let(:site) do
          site = build(:site)
          Service::Site.new(site).tap do |service|
            service.create
            service.update_billable_items({}, { logo: AddonPlan.get('logo', 'disabled').id })
          end
          site
        end

        it 'unsuspend all billable items' do
          site.reload.billable_items.should have(13).items
          site.billable_items.addon_plans.where(item_id: @logo_addon_plan_2).where(state: 'trial').should have(1).item

          site.suspend!

          site.reload.billable_items.addon_plans.where(item_id: @logo_addon_plan_2).where(state: 'suspended').should have(1).item

          site.unsuspend!

          site.reload.billable_items.should have(13).items
          site.billable_items.app_designs.where(item_id: @classic_design).where(state: 'beta').should have(1).item
          site.billable_items.app_designs.where(item_id: @flat_design).where(state: 'beta').should have(1).item
          site.billable_items.app_designs.where(item_id: @light_design).where(state: 'beta').should have(1).item
          site.billable_items.addon_plans.where(item_id: @video_player_addon_plan_1).where(state: 'beta').should have(1).item
          site.billable_items.addon_plans.where(item_id: @lightbox_addon_plan_1).where(state: 'subscribed').should have(1).item
          site.billable_items.addon_plans.where(item_id: @image_viewer_addon_plan_1).where(state: 'beta').should have(1).item
          site.billable_items.addon_plans.where(item_id: @stats_addon_plan_1).where(state: 'subscribed').should have(1).item
          site.billable_items.addon_plans.where(item_id: @logo_addon_plan_2).where(state: 'trial').should have(1).item
          site.billable_items.addon_plans.where(item_id: @controls_addon_plan_1).where(state: 'beta').should have(1).item
          site.billable_items.addon_plans.where(item_id: @initial_addon_plan_1).where(state: 'beta').should have(1).item
          site.billable_items.addon_plans.where(item_id: @sharing_addon_plan_1).where(state: 'beta').should have(1).item
          site.billable_items.addon_plans.where(item_id: @api_addon_plan_1).where(state: 'subscribed').should have(1).item
          site.billable_items.addon_plans.where(item_id: @support_addon_plan_1).where(state: 'subscribed').should have(1).item
        end
      end
    end

    describe "before transition on archive" do
      it "set archived_at" do
        expect { site.archive! }.to change(site, :archived_at)
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

  describe '#trial_end_date_for_billable_item' do
    let(:addon_plan) { create(:addon_plan) }
    before do
      @billable_item_activity1 = create(:billable_item_activity, item: addon_plan, state: 'trial', created_at: 31.days.ago.midnight)
      @billable_item_activity2 = create(:billable_item_activity, item: addon_plan, state: 'trial', created_at: 30.days.ago.midnight)
      @billable_item_activity3 = create(:billable_item_activity, item: addon_plan, state: 'trial', created_at: 29.days.ago.midnight)
      @billable_item_activity4 = create(:billable_item_activity, item: addon_plan, state: 'trial', created_at: 28.days.ago.midnight)
      @billable_item_activity5 = create(:billable_item_activity, item: addon_plan, state: 'trial', created_at: 14.days.ago.midnight)
      @billable_item_activity6 = create(:billable_item_activity, item: addon_plan, state: 'trial', created_at: Time.now.utc.midnight)
    end

    it 'works' do
      @billable_item_activity1.site.trial_end_date_for_billable_item(addon_plan).should eq 1.day.ago.midnight
      @billable_item_activity2.site.trial_end_date_for_billable_item(addon_plan).should eq Time.now.utc.midnight
      @billable_item_activity3.site.trial_end_date_for_billable_item(addon_plan).should eq 1.day.from_now.midnight
      @billable_item_activity4.site.trial_end_date_for_billable_item(addon_plan).should eq 2.days.from_now.midnight
      @billable_item_activity5.site.trial_end_date_for_billable_item(addon_plan).should eq 16.days.from_now.midnight
      @billable_item_activity6.site.trial_end_date_for_billable_item(addon_plan).should eq 30.days.from_now.midnight
      create(:site).trial_end_date_for_billable_item(addon_plan).should be_nil
    end
  end

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
#  index_sites_on_user_id                           (user_id)
#

