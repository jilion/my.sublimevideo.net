require 'spec_helper'

describe SiteModules::Scope do
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
      Timecop.travel(30.days.ago) do
        create(:billable_item, site: site2, item: @logo_addon_plan_1, state: 'trial')
      end
      Timecop.travel(31.days.ago) { create(:billable_item, site: site2, item: @logo_addon_plan_2, state: 'trial') }
      create(:billable_item, site: site2, item: @stats_addon_plan_1, state: 'trial')
      create(:billable_item, site: site1, item: @support_addon_plan_2, state: 'subscribed')
      create(:billable_item, site: site3, item: @support_addon_plan_2, state: 'subscribed')
    end

    describe ".paying" do
      it { Site.paying.all.should =~ [site1] }
    end

    describe ".free" do
      it { Site.free.all.should =~ [site2] }
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


  describe ".refunded" do
    before do
      @site_refunded_1     = create(:site, user: user, state: 'archived', refunded_at: Time.now.utc)
      @site_not_refunded_1 = create(:site, user: user, refunded_at: Time.now.utc)
      @site_not_refunded_2 = create(:site, user: user, state: 'archived', refunded_at: nil)
    end

    specify { Site.refunded.all.should =~ [@site_refunded_1] }
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

end
