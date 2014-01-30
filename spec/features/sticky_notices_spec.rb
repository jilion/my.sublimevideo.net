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
      page.should have_no_content I18n.t("user.credit_card.add")
    end
  end
end
