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

    # describe ".with_addon_active" do
    #   Addons::Addonship::ACTIVE_STATES.each do |state|
    #     context "addonship is in #{state}" do
    #       before do
    #         create(:addonship, site: site1, addon: addon, state: state)
    #         create(:addonship, site: site2, addon: addon, state: 'inactive')
    #       end

    #       it { Site.with_addon_active('foo', 'bar').all.should =~ [site1] }
    #     end
    #   end

    #   Addons::Addonship::INACTIVE_STATES.each do |state|
    #     context "addonship is in #{state}" do
    #       before do
    #         create(:addonship, site: site1, addon: addon, state: state)
    #       end

    #       it { Site.with_addon_active('foo', 'bar').all.should be_empty }
    #     end
    #   end
    # end

    describe ".with_out_of_trial_addons" do
      before do
        @addonship1 = create(:trial_addonship, site: site1, addon: @logo_sublime_addon, trial_started_on: (30.days - 1.second).ago)
        @addonship2 = create(:trial_addonship, site: site2, addon: @logo_no_logo_addon, trial_started_on: (30.days + 1.second).ago)
        @addonship3 = create(:trial_addonship, site: site1, addon: @stats_standard_addon)
        @addonship4 = create(:subscribed_addonship, site: site2, addon: @support_standard_addon, trial_started_on: (30.days + 1.second).ago)
        @addonship5 = create(:subscribed_addonship, site: site1, addon: @support_vip_addon)
        @addonship6 = create(:inactive_addonship, site: site2)
      end

      it { Site.with_out_of_trial_addons.all.should =~ [site2] }
    end

    describe ".paying" do
      before do
        @addonship1 = create(:trial_addonship, site: site1, addon: @logo_sublime_addon, trial_started_on: (30.days - 1.second).ago)
        @addonship2 = create(:trial_addonship, site: site2, addon: @logo_no_logo_addon, trial_started_on: (30.days + 1.second).ago)
        @addonship3 = create(:trial_addonship, site: site1, addon: @stats_standard_addon)
        @addonship5 = create(:subscribed_addonship, site: site1, addon: @support_vip_addon)
        @addonship6 = create(:inactive_addonship, site: site2)
      end

      it { Site.paying.all.should =~ [site1] }
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

end
