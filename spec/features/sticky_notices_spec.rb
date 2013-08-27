require 'spec_helper'

feature "Sticky notices" do
  context "nothing to say to the user" do
    background do
      sign_in_as :user
      @site = build(:site, user: @current_user)
      SiteManager.new(@site).create
      go 'my', '/sites'
    end

    scenario "no notice" do
      page.should have_no_content I18n.t("user.credit_card.will_expire")
      page.should have_no_content I18n.t("user.credit_card.expired")
      page.should have_no_content I18n.t("app.update_it")
    end
  end

  context "credit card will expire this month" do
    background do
      sign_in_as :user, cc_expire_on: Time.utc(Time.now.utc.year, Time.now.utc.month).end_of_month.to_date
      @site = build(:site, user: @current_user)
      SiteManager.new(@site).create
      @current_user.should be_cc_expire_this_month
      go 'my', '/sites'
    end

    context "user is billable" do
      background do
        create(:billable_item, site: @site, item: create(:addon_plan), state: 'subscribed')
        @current_user.should be_billable
        go 'my', '/sites'
      end

      scenario "shows a notice" do
        page.should have_content I18n.t("user.credit_card.will_expire")
        page.should have_content I18n.t("app.update_it")
      end
    end
  end

  context "credit card is expired" do
    background do
      sign_in_as :user, cc_expire_on: 2.years.ago
      go 'my', '/sites'
    end

    context "user is not billable" do
      scenario "doesn't show a notice" do
        @current_user.should_not be_billable
        current_url.should eq "http://my.sublimevideo.dev/assistant/new-site"
      end
    end

    context "user is billable" do
      background do
        @site = build(:site, user: @current_user)
        SiteManager.new(@site).create
        create(:billable_item, site: @site, item: create(:addon_plan), state: 'subscribed')
        @current_user.should be_billable
        go 'my', '/sites'
      end

      scenario "shows a notice" do
        page.should have_content I18n.t("user.credit_card.expired")
        page.should have_content I18n.t("app.update_it")
      end
    end
  end

  context "billing address is incomplete" do
    context "user is not billable" do
      background do
        sign_in_as :user, billing_address_1: ''
        @current_user.should_not be_billable
        @current_user.should be_cc
        @current_user.should_not be_billing_address_complete
        go 'my', '/sites'
      end

      scenario "doesn't show a notice" do
        @current_user.should_not be_billable

        current_url.should eq "http://my.sublimevideo.dev/assistant/new-site"
        page.should have_no_content I18n.t("user.billing_address.incomplete")
      end
    end

    context "user is billable" do
      context "user has a credit card" do
        background do
          sign_in_as :user, billing_address_1: ''
          @site = build(:site, user: @current_user)
          SiteManager.new(@site).create
          create(:billable_item, site: @site, item: create(:addon_plan), state: 'subscribed')
          @current_user.should be_billable
          @current_user.should be_cc
          @current_user.should_not be_billing_address_complete
          go 'my', '/sites'
        end

        scenario "shows a notice" do
          page.should have_content I18n.t("user.billing_address.complete_it")
        end
      end

      context "user has no credit card" do
        background do
          sign_in_as :user, without_cc: true, billing_address_1: ''
          @site = build(:site, user: @current_user)
          SiteManager.new(@site).create
          create(:billable_item, site: @site, item: create(:addon_plan), state: 'subscribed')
          @current_user.should be_billable
          @current_user.should_not be_cc
          @current_user.should_not be_billing_address_complete
          go 'my', '/sites'
        end

        scenario "shows a notice" do
          page.should have_content I18n.t("user.billing_address.complete_it")
        end
      end
    end
  end
end
