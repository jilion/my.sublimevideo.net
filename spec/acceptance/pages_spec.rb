require 'spec_helper'

feature "Pages:" do
    
  scenario "terms" do
    visit "/terms"
    page.should have_content('Terms & Conditions')
  end
  
  scenario "privacy" do
    visit "/privacy"
    page.should have_content('Privacy Policy')
  end
  
  context "public release only", :release => :public do
    scenario "suspended" do
      sign_in_as :user
      @current_user.suspend
      visit "/suspended"
      page.should have_content('Your account is suspended')
    end
  end
  
end