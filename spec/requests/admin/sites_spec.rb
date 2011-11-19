require 'spec_helper'

feature "Sites pagination:" do

  background do
    sign_in_as :admin
    Site.delete_all
    Factory.create(:site)
    Responders::PaginatedResponder.stub(:per_page).and_return(1)
  end

  scenario "pagination links displayed only if count of sites > Site.per_page" do
    go 'admin', 'sites'

    page.should have_no_css 'nav.pagination'
    page.should have_no_css 'span.current'
    page.should have_no_selector "a[rel='next']"

    Factory.create(:site)
    go 'admin', 'sites'

    page.should have_css 'nav.pagination'
    page.should have_css 'span.current'
    page.should have_selector "a[rel='next']"
  end

end
