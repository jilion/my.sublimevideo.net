require 'spec_helper'

feature "Invoice actions:" do

  background do
    sign_in_as :user
  end

  scenario "views site invoices (with 0 past invoices)" do
    site = Factory(:site_with_invoice, plan_id: @dev_plan.id, user: @current_user, hostname: 'google.com')

    visit "/sites"
    click_link "Edit google.com"
    click_link "Invoices"

    current_url.should =~ %r(http://[^/]+/sites/#{site.token}/invoices)
    page.should have_content('google.com')

    page.should have_content('Past invoices')
    page.should have_content('None.')
  end

  scenario "views site invoices (with 0 past invoices and 1 next invoice)" do
    site = Factory(:site_with_invoice, plan_id: @dev_plan.id, user: @current_user, hostname: 'google.com')

    visit "/sites"
    click_link "Edit google.com"
    click_link "Invoices"

    current_url.should =~ %r(http://[^/]+/sites/#{site.token}/invoices)
    page.should have_content('google.com')

    page.should_not have_content('Next invoice')

    page.should have_content('Past invoices')
    page.should have_content('None.')
  end

  scenario "views site invoices (with 1 invoice and 1 next invoice)" do
    site = Factory(:site_with_invoice, plan_id: @paid_plan.id, user: @current_user, hostname: 'google.com')

    visit "/sites"
    click_link "Edit google.com"
    click_link "Invoices"

    current_url.should =~ %r(http://[^/]+/sites/#{site.token}/invoices)
    page.should have_content('google.com')

    page.should have_content('Next invoice')
    page.should have_content("$#{Invoice.build_next(site: site).amount / 100.0}")
    page.should have_content("on #{I18n.l(site.plan_cycle_ended_at.tomorrow, :format => :d_b_Y)}")

    page.should have_content('Past invoices')
    page.should have_content("Charged on #{I18n.l(site.last_invoice.paid_at, :format => :minutes_timezone)}")
  end

  pending "views site invoices"

  pending "view invoice"

  pending "pay failed invoice"

end
