require 'spec_helper'

feature "Users pagination:" do

  background do
    sign_in_as :admin
    create(:site) # this create a billable user
    allow(PaginatedResponder).to receive(:per_page).and_return(1)
  end

  scenario "pagination links displayed only if count of users > User.per_page" do
    go 'admin', 'users'

    expect(page).to have_no_css 'nav.pagination'
    expect(page).to have_no_css 'em.current'
    expect(page).to have_no_selector "a[rel='next']"

    create(:site) # this create a billable user
    go 'admin', 'users'

    expect(page).to have_css 'nav.pagination'
    expect(page).to have_css 'em.current'
    expect(page).to have_selector "a[rel='next']"
  end

end

feature "Users page" do

  background do
    sign_in_as :admin
    @site = create(:site) # this create a billable user
    create(:invoice, site: @site)
  end

  scenario "page displays well" do
    go 'admin', "users/#{@site.user.to_param}"

    expect(page).to have_content @site.user.name
  end

end
