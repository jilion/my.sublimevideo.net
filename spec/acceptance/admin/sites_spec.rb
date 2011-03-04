require 'spec_helper'

feature "Sites pagination:" do
  background do
    sign_in_as :admin
    Responders::PaginatedResponder.stub(:per_page).and_return(1)
    Factory(:site)
  end

  scenario "pagination links displayed only if count of sites > Site.per_page" do
    visit "/admin/sites"
    page.should have_no_css('nav.pagination')
    page.should have_no_css('span.prev')
    page.should have_no_css('em.current')
    page.should have_no_css('a.next')
    
    Factory(:site)
    visit "/admin/sites"
    
    page.should have_css('nav.pagination')
    page.should have_css('span.prev')
    page.should have_css('em.current')
    page.should have_css('a.next')
  end
end
