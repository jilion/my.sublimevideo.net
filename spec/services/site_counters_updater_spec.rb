require 'fast_spec_helper'
require 'active_support/core_ext'
require 'config/sidekiq'
require 'support/matchers/sidekiq_matchers'

require 'services/site_counters_updater'

SiteAdminStat = Class.new unless defined?(SiteAdminStat)
AddonPlan = Class.new unless defined?(AddonPlan)
SiteStat = Class.new unless defined?(SiteStat)
VideoTag = Class.new unless defined?(VideoTag)
Site = Class.new unless defined?(Site)

describe SiteCountersUpdater do
  let(:site) { double(:site, id: 2).as_null_object }
  let(:updater) { SiteCountersUpdater.new(site).update }

  before { AddonPlan.stub(:get) }

  describe '.update_not_archived_sites' do
    it 'calls #update and #update_not_archived_sites on each non-archived sites' do
      Site.stub_chain(:not_archived, :select, :find_each).and_yield(site)
      described_class.should delay(:update, queue: 'my-low').with(site.id)

      described_class.update_not_archived_sites
    end
  end

  describe '#update' do
    before {
      SiteAdminStat.stub(:last_days_starts) { [1,2,3] }
      SiteStat.stub(:last_days_starts) { [1,2,3] }
      VideoTag.stub(:count) { 0 }
    }

    it "updates last_30_days_admin_starts from SiteAdminStat" do
      expect(SiteAdminStat).to receive(:last_days_starts).with(site, 30) { [1,2,3] }
      expect(site).to receive(:last_30_days_admin_starts=).with(6)
      updater.update
    end

    it "saves site" do
      expect(site).to receive(:save)
      updater.update
    end

    context "with site.first_admin_starts_on unset" do
      before { site.stub(:first_admin_starts_on) { nil } }

      context "with some last_30_days_admin_starts" do
        before { site.stub(:last_30_days_admin_starts) { 1 } }

        it "sets first_admin_starts_on" do
          expect(site).to receive(:first_admin_starts_on=).with(Date.yesterday)
          updater.update
        end
      end

      context "with no last_30_days_admin_starts" do
        before { site.stub(:last_30_days_admin_starts) { 0 } }

        it "doesn't sets first_admin_starts_on" do
          expect(site).to_not receive(:first_admin_starts_on=)
          updater.update
        end
      end
    end

    context "with site.first_admin_starts_on set" do
      before { site.stub(:first_admin_starts_on) { Date.yesterday } }

      it "doesn't set first_admin_starts_on" do
        expect(site).to_not receive(:first_admin_starts_on=)
        updater.update
      end
    end

    context "with some last_30_days_admin_starts" do
      before { site.stub(:last_30_days_admin_starts) { 1 } }

      context "with realtime stats addon" do
        before { site.stub(:subscribed_to?) { true } }

        it "updates last_30_days_starts_array from SiteStat" do
          expect(SiteStat).to receive(:last_days_starts).with(site, 30) { [1,2,3] }
          expect(site).to receive(:last_30_days_starts_array=).with([1,2,3])
          updater.update
        end

        it "updates last_30_days_starts from SiteStat" do
          expect(SiteStat).to receive(:last_days_starts).with(site, 30) { [1,2,3] }
          expect(site).to receive(:last_30_days_starts=).with(6)
          updater.update
        end
      end

      context "without realtime stats addon" do
        before { site.stub(:subscribed_to?) { false } }

        it "sets last_30_days_starts_array to empty array" do
          expect(site).to receive(:last_30_days_starts_array=).with([])
          updater.update
        end

        it "sets last_30_days_starts to nil" do
          expect(site).to receive(:last_30_days_starts=).with(nil)
          updater.update
        end
      end

      it "updates last_30_days_video_tags from VideoTag" do
        expect(VideoTag).to receive(:count).with(site_token: site.token, last_30_days_active: true, with_valid_uid: true) { 5 }
        expect(site).to receive(:last_30_days_video_tags=).with(5)
        updater.update
      end
    end

    context "with no last_30_days_admin_starts" do
      before { site.stub(:last_30_days_admin_starts) { 0 } }

      it "doesn't update last_30_days_starts_array from SiteStat" do
        expect(SiteStat).to_not receive(:last_days_starts)
        expect(site).to receive(:last_30_days_starts_array=).with(30.times.map { 0 })
        updater.update
      end

      it "doesn't update last_30_days_starts from SiteStat" do
        expect(SiteStat).to_not receive(:last_days_starts)
        expect(site).to receive(:last_30_days_starts=).with(0)
        updater.update
      end

      it "doesn't update last_30_days_video_tags from VideoTag" do
        expect(VideoTag).to_not receive(:count)
        expect(site).to receive(:last_30_days_video_tags=).with(0)
        updater.update
      end
    end

  end

end
