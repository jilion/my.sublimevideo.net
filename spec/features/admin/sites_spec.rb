require 'spec_helper'

feature 'Sites pagination' do
  background do
    sign_in_as :admin
    Site.delete_all
    create(:site)
    allow(PaginatedResponder).to receive(:per_page).and_return(1)
  end

  scenario 'pagination links displayed only if count of sites > Site.per_page' do
    go 'admin', 'sites'

    expect(page).to have_no_css 'nav.pagination'
    expect(page).to have_no_css 'em.current'
    expect(page).to have_no_selector "a[rel='next']"

    create(:site)
    go 'admin', 'sites'

    expect(page).to have_css 'nav.pagination'
    expect(page).to have_css 'em.current'
    expect(page).to have_selector "a[rel='next']"
  end
end

feature 'Sites page' do
  background do
    stub_site_stats
    sign_in_as :admin
    @site = create(:site) # this create a billable user
    create(:invoice, site: @site)
  end

  scenario 'page displays well' do
    go 'admin', "sites/#{@site.to_param}"

    expect(page).to have_content @site.id
    expect(page).to have_content @site.token
    expect(page).to have_content @site.hostname
  end
end
