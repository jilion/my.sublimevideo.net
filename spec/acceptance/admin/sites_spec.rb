require File.dirname(__FILE__) + '/../acceptance_helper'

feature "Sites pagination:" do
  background do
    sign_in_as :admin
    Site.stub!(:per_page).and_return(1)
  end
  
  scenario "pagination links displayed only if count of sites > Site.per_page" do
    Factory(:site)
    Site.all.size.should == 1
    visit "/admin/sites"
    page.should have_no_css('div.pagination')
    page.should have_no_css('span.previous_page')
    page.should have_no_css('em.current_page')
    page.should have_no_css('a.next_page')
    
    Factory(:site)
    visit "/admin/sites"
    
    page.should have_css('div.pagination')
    page.should have_css('span.previous_page')
    page.should have_css('em.current_page')
    page.should have_css('a.next_page')
  end
end