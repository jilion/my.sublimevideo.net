require 'spec_helper'

feature "Invoice actions:" do

  background do
    sign_in_as :user
  end

  scenario "views site invoices (with 0 invoices)" do
    site = Factory(:site, plan_id: @dev_plan.id, user: @current_user, hostname: 'google.com')

    visit "/sites"
    click_link "Edit google.com"
    click_link "Invoices"

    current_url.should =~ %r(http://[^/]+/sites/#{site.token}/invoices)
    page.should have_content('google.com')
    page.should have_content('Past invoices')
    page.should have_content('None.')
  end

  scenario "views site invoices (with 1 invoice)" do
    site = Factory(:site, plan_id: @paid_plan.id, user: @current_user, hostname: 'google.com')

    visit "/sites"
    click_link "Edit google.com"
    click_link "Invoices"

    current_url.should =~ %r(http://[^/]+/sites/#{site.token}/invoices)
    page.should have_content('google.com')
    page.should have_content('Past invoices')
    page.should have_content("Charged on #{l(site.last_invoice.paid_at, :format => :minutes_timezone)}")
  end

  pending "views site invoices"

  pending "view invoice"

  pending "pay failed invoice"

end