require 'spec_helper'

feature "Invoice actions:" do

  background do
    sign_in_as :user
  end

  scenario "views site invoices (with 0 invoices)" do
    site = Factory(:site, :user => @current_user, :hostname => 'google.com')

    visit "/sites"
    click_link "Edit google.com"
    click_link "Invoices"

    current_url.should =~ %r(http://[^/]+/sites/#{site.token}/invoices)
    page.should have_content('google.com')
    page.should have_content('Past invoices')
    page.should have_content('None.')
  end

  pending "views site invoices"

  pending "view invoice"

  pending "pay failed invoice"

end