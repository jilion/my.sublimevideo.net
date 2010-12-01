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
  
  scenario "suspended" do
    feature "non-suspended user" do
      scenario "privacy" do
        sign_in_as :user
        visit "/suspended"
        
        current_url.should =~ %r(^http://[^/]+/sites$)
        page.should_not have_content('Your account is suspended')
      end
    end
    
    feature "suspended user", :focus => true do
      scenario "privacy" do
        sign_in_as :user, { :cc_expire_on => 2.days.ago }
        @invoice = Factory(:invoice, :user => @current_user, :state => 'failed', :failed_at => Time.now.utc, :last_error => "Credit Card expired.")
        @current_user.suspend
        visit "/suspended"
        
        current_url.should =~ %r(^http://[^/]+/suspended$)
        page.should have_content('Your account is suspended')
        
        page.should have_content("This Credit Card is expired, please update it.")
        page.should have_content("Visa ending in 1234")
        page.should have_content("Charging has failed on #{I18n.l(@invoice.failed_at, :format => :minutes)} with the following error: \"#{@invoice.last_error}\".")
      end
    end
  end
  
end