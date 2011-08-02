require 'spec_helper'

feature "Users pagination:" do
  background do
    sign_in_as :admin
    Responders::PaginatedResponder.stub(:per_page).and_return(1)
  end

  scenario "pagination links displayed only if count of users > User.per_page" do
    FactoryGirl.create(:site)
    User.count.should == 1
    visit "/admin/users"

    page.should have_no_css('nav.pagination')
    page.should have_no_css('span.prev')
    page.should have_no_css('em.current')
    page.should have_no_css('a.next')

    FactoryGirl.create(:site)
    User.count.should == 2
    visit "/admin/users"

    page.should have_css('nav.pagination')
    page.should have_css('span.prev')
    page.should have_css('em.current')
    page.should have_css('a.next')
  end
end
