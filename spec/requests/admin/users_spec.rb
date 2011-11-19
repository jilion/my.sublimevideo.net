require 'spec_helper'

feature "Users pagination:" do

  background do
    sign_in_as :admin
    Factory.create(:site) # this create a billable user
    Responders::PaginatedResponder.stub(:per_page).and_return(1)
  end

  scenario "pagination links displayed only if count of users > User.per_page" do
    go 'admin', 'users'

    page.should have_no_css 'nav.pagination'
    page.should have_no_css 'span.current'
    page.should have_no_selector "a[rel='next']"

    Factory.create(:site) # this create a billable user
    go 'admin', 'users'

    page.should have_css 'nav.pagination'
    page.should have_css 'span.current'
    page.should have_selector "a[rel='next']"
  end

end
