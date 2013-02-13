require 'spec_helper'

feature "Sites pagination:" do

  background do
    sign_in_as :admin
    Site.delete_all
    create(:site)
    PaginatedResponder.stub(:per_page).and_return(1)
  end

  scenario "pagination links displayed only if count of sites > Site.per_page" do
    go 'admin', 'sites'

    page.should have_no_css 'nav.pagination'
    page.should have_no_css 'em.current'
    page.should have_no_selector "a[rel='next']"

    create(:site)
    go 'admin', 'sites'

    page.should have_css 'nav.pagination'
    page.should have_css 'em.current'
    page.should have_selector "a[rel='next']"
  end

end

feature "Sites page" do

  background do
    sign_in_as :admin
    @site = create(:site) # this create a billable user
    create(:invoice, site: @site)
  end

  scenario "page displays well" do
    go 'admin', "sites/#{@site.to_param}"

    page.should have_content @site.id
    page.should have_content @site.token
    page.should have_content @site.hostname
  end

end
