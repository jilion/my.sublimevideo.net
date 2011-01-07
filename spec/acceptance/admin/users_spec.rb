require 'spec_helper'

feature "Users pagination:" do
  background do
    sign_in_as :admin
    User.stub!(:per_page).and_return(1)
  end
  
  scenario "pagination links displayed only if count of users > User.per_page" do
    Factory(:user)
    Admin.all.size.should == 1
    visit "/admin/users"
    page.should have_no_css('div.pagination')
    page.should have_no_css('span.previous_page')
    page.should have_no_css('em.current_page')
    page.should have_no_css('a.next_page')
    
    Factory(:user)
    visit "/admin/users"
    save_and_open_page
    page.should have_css('div.pagination')
    page.should have_css('span.previous_page')
    page.should have_css('em.current_page')
    page.should have_css('a.next_page')
  end
end