# coding: utf-8
require 'spec_helper'

feature "Refunds" do

  context "logged-in user" do
    background do
      sign_in_as :user
    end

    scenario "visit /refund with no sites refundable" do
      visit '/refund'
      page.should have_content "Refund"
      page.should have_content I18n.t('site.refund.no_refund_possible')
    end

    scenario "visit /refund with 1 site refundable" do
      @site = Factory(:site_with_invoice, user: @current_user, hostname: 'rymai.com')

      visit '/refund'
      page.should have_content "Refund"

      select "rymai.com", :from => "site_id"
      click_button I18n.t('site.refund.request')

      @site.reload.should be_archived
      @site.should be_refunded

      current_url.should =~ %r(^http://[^/]+/refund$)
      page.should have_content I18n.t('site.refund.refunded', hostname: 'rymai.com')
      page.should have_content I18n.t('site.refund.no_refund_possible')
    end

    scenario "visit /refund with 1 site refundable failing" do
      @site = Factory(:site_with_invoice, user: @current_user, hostname: 'rymai.com')

      visit '/refund'
      page.should have_content "Refund"
      @site.update_attribute(:hostname, 'rymai') # make it invalid

      select "rymai.com", :from => "site_id"
      click_button I18n.t('site.refund.request')

      @site.reload.should_not be_archived
      @site.should_not be_refunded

      current_url.should =~ %r(^http://[^/]+/refund$)
      page.should have_content I18n.t('site.refund.refund_unsuccessful', hostname: 'rymai')
      page.should have_no_content I18n.t('site.refund.no_refund_possible')
    end

    scenario "not suspended user" do
      visit "/refund"
      current_url.should =~ %r(^http://[^/]+/refund$)
    end

    scenario "suspended user" do
      @current_user.suspend
      visit "/refund"
      current_url.should =~ %r(http://[^/]+/refund)
    end

  end
end
