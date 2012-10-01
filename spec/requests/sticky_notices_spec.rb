require 'spec_helper'

feature "Sticky notices" do
  context "no notice" do
    background do
      sign_in_as :user, kill_user: true
      create(:site, user: @current_user)
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
      sign_in_as :user, cc_expire_on: Time.utc(Time.now.utc.year, Time.now.utc.month).end_of_month.to_date, kill_user: true
      @current_user.should be_cc_expire_this_month
      go 'my', '/sites'
    end

    context "user is billable" do
      background do
        create(:subscribed_addonship, site: create(:site, user: @current_user))
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
      sign_in_as :user, cc_expire_on: 2.years.ago, kill_user: true
      go 'my', '/sites'
    end

    context "user is not billable" do
      scenario "doesn't show a notice" do
        @current_user.should_not be_billable
        current_url.should eq "http://my.sublimevideo.dev/sites/new"
      end
    end

    context "user is billable" do
      background do
        create(:subscribed_addonship, site: create(:site, user: @current_user))
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
        sign_in_as :user, kill_user: true, billing_address_1: ''
        @current_user.should_not be_billable
        @current_user.should be_cc
        @current_user.should_not be_billing_address_complete
        go 'my', '/sites'
      end

      scenario "doesn't show a notice" do
        @current_user.should_not be_billable

        current_url.should eq "http://my.sublimevideo.dev/sites/new"
        page.should have_no_content I18n.t("user.billing_address.incomplete")
      end
    end

    context "user is billable" do
      context "user has a credit card" do
        background do
          sign_in_as :user, billing_address_1: ''
          create(:subscribed_addonship, site: create(:site, user: @current_user))
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
          create(:subscribed_addonship, site: create(:site, user: @current_user))
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
