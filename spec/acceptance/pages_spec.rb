require File.dirname(__FILE__) + '/acceptance_helper'

feature "Pages:" do
    
  scenario "terms" do
    visit "/terms"
    page.should have_content('Terms & Conditions')
  end
  
  scenario "docs" do
    visit "/docs"
    page.should have_content('Documentation')
  end
  
  scenario "support" do
    visit "/support"
    page.should have_content('Support')
  end
  
  scenario "suspended" do
    sign_in_as_user
    @current_user.suspend
    visit "/suspended"
    page.should have_content('Your account is suspended')
  end
  
end