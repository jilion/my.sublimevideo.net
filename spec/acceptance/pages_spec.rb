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
  
end