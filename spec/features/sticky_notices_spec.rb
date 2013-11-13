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
      expect(page).to have_no_content I18n.t("user.credit_card.will_expire")
      expect(page).to have_no_content I18n.t("user.credit_card.expired")
      expect(page).to have_no_content I18n.t("user.credit_card.add")
    end
  end

  context "credit card will expire this month" do
    background do
      sign_in_as :user, cc_expire_on: Time.utc(Time.now.utc.year, Time.now.utc.month).end_of_month.to_date
      @site = build(:site, user: @current_user)
      SiteManager.new(@site).create
      expect(@current_user).to be_cc_expire_this_month
      go 'my', '/sites'
    end

    context "user is billable" do
      background do
        create(:billable_item, site: @site, item: create(:addon_plan), state: 'subscribed')
        expect(@current_user).to be_billable
        go 'my', '/sites'
      end

      scenario "shows a notice" do
        expect(page).to have_content I18n.t("user.credit_card.will_expire")
        expect(page).to have_content I18n.t("user.credit_card.add")
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
        expect(@current_user).not_to be_billable
        expect(current_url).to eq "http://my.sublimevideo.dev/assistant/new-site"
      end
    end

    context "user is billable" do
      background do
        @site = build(:site, user: @current_user)
        SiteManager.new(@site).create
        create(:billable_item, site: @site, item: create(:addon_plan), state: 'subscribed')
        expect(@current_user).to be_billable
        go 'my', '/sites'
      end

      scenario "shows a notice" do
        expect(page).to have_content I18n.t("user.credit_card.expired")
        expect(page).to have_content I18n.t("user.credit_card.add")
      end
    end
  end

  context "billing address is incomplete" do
    context "user is not billable" do
      background do
        sign_in_as :user, billing_address_1: ''
        expect(@current_user).not_to be_billable
        expect(@current_user).to be_cc
        expect(@current_user).not_to be_billing_address_complete
        go 'my', '/sites'
      end

      scenario "doesn't show a notice" do
        expect(@current_user).not_to be_billable

        expect(current_url).to eq "http://my.sublimevideo.dev/assistant/new-site"
        expect(page).to have_no_content I18n.t("user.billing_address.incomplete")
      end
    end

    context "user is billable" do
      context "user has a credit card" do
        background do
          sign_in_as :user, billing_address_1: ''
          @site = build(:site, user: @current_user)
          SiteManager.new(@site).create
          create(:billable_item, site: @site, item: create(:addon_plan), state: 'subscribed')
          expect(@current_user).to be_billable
          expect(@current_user).to be_cc
          expect(@current_user).not_to be_billing_address_complete
          go 'my', '/sites'
        end

        scenario "shows a notice" do
          expect(page).to have_content I18n.t("user.billing_address.complete_it")
        end
      end

      context "user has no credit card" do
        background do
          sign_in_as :user, without_cc: true, billing_address_1: ''
          @site = build(:site, user: @current_user)
          SiteManager.new(@site).create
          create(:billable_item, site: @site, item: create(:addon_plan), state: 'subscribed')
          expect(@current_user).to be_billable
          expect(@current_user).not_to be_cc
          expect(@current_user).not_to be_billing_address_complete
          go 'my', '/sites'
        end

        scenario "shows a notice" do
          expect(page).to have_content I18n.t("user.billing_address.complete_it")
        end
      end
    end
  end
end
