require 'spec_helper'

describe "Pages" do
  before(:all) { @worker = Delayed::Worker.new }
  
  feature "Pages:" do
    scenario "terms" do
      visit "/terms"
      page.should have_content('Terms & Conditions')
    end
    
    scenario "privacy" do
      visit "/privacy"
      page.should have_content('Privacy Policy')
    end
    
    feature "suspended" do
      
      feature "non-suspended user" do
        scenario "privacy" do
          sign_in_as :user
          visit "/suspended"
          
          current_url.should =~ %r(^http://[^/]+/sites$)
          page.should_not have_content('Your account is suspended')
        end
      end
      
      feature "suspended user" do
        background do
          sign_in_as :user, { :cc_expire_on => 2.days.ago }
          @current_user.cc_expire_on = 2.days.ago
          @current_user.save(:validate => false)
          @current_user.should be_cc_expired
          @invoice = Factory(:invoice, :user => @current_user, :state => 'failed', :started_at => Time.utc(2010,1), :ended_at => Time.utc(2010,1), :failed_at => Time.utc(2010,2,10), :last_error => "Credit Card expired.")
          @current_user.suspend
          visit "/suspended"
        end
        
        scenario "suspended page" do
          current_url.should =~ %r(^http://[^/]+/suspended$)
          page.should have_content('Your account is suspended')
          
          page.should have_content("This Credit Card is expired, please update it.")
          page.should have_content("Visa ending in 1234")
          page.should have_content("Update your Credit Card")
          page.should have_content("January 2010 - Charging has failed on #{I18n.l(@invoice.failed_at, :format => :minutes)} with the following error: \"#{@invoice.last_error}\".")
        end
        
        scenario "updating credit card" do
          click_link_or_button "Update your Credit Card"
          
          VCR.use_cassette('credit_card_visa_validation') do
            fill_in "user_cc_full_name", :with => "John Doe"
            fill_in "user_cc_number", :with => "4111111111111111"
            fill_in "user_cc_verification_value", :with => "111"
            click_button "Update"
          end
          
          current_url.should =~ %r(^http://[^/]+/suspended$)
        end
        
        scenario "updating credit card and paying the only failed invoice" do
          click_link_or_button "Update your Credit Card"
          
          VCR.use_cassette('credit_card_visa_validation') do
            fill_in "user_cc_full_name", :with => "John Doe"
            fill_in "user_cc_number", :with => "4111111111111111"
            fill_in "user_cc_verification_value", :with => "111"
            click_button "Update"
          end
          
          current_url.should =~ %r(^http://[^/]+/suspended$)
          VCR.use_cassette "ogone_visa_payment_2000_alias" do
            click_button "Pay the January 2010 invoice"
          end
          
          current_url.should =~ %r(^http://[^/]+/suspended$)
          
          @worker.work_off # delayed unsuspend is done
          
          visit '/suspended'
          current_url.should =~ %r(^http://[^/]+/sites$)
        end
        
        scenario "updating credit card and paying first failed invoice, then the second failed invoice" do
          @invoice2 = Factory(:invoice, :user => @current_user, :state => 'failed', :started_at => Time.utc(2010,2), :ended_at => Time.utc(2010,2), :failed_at => Time.utc(2010,3,10), :last_error => "Credit Card invalid.")
          
          visit '/suspended'
          page.should have_content("January 2010 - Charging has failed on #{I18n.l(@invoice.failed_at, :format => :minutes)} with the following error: \"#{@invoice.last_error}\".")
          page.should have_content("February 2010 - Charging has failed on #{I18n.l(@invoice2.failed_at, :format => :minutes)} with the following error: \"#{@invoice2.last_error}\".")
          
          click_link_or_button "Update your Credit Card"
          
          VCR.use_cassette('credit_card_visa_validation') do
            fill_in "user_cc_full_name", :with => "John Doe"
            fill_in "user_cc_number", :with => "4111111111111111"
            fill_in "user_cc_verification_value", :with => "111"
            click_button "Update"
          end
          
          current_url.should =~ %r(^http://[^/]+/suspended$)
          VCR.use_cassette "ogone_visa_payment_2000_alias" do
            click_button "Pay the January 2010 invoice"
          end
          
          current_url.should =~ %r(^http://[^/]+/suspended$)
          page.should_not have_content("January 2010")
          page.should have_content("February 2010")
          VCR.use_cassette "ogone_visa_payment_2000_alias" do
            click_button "Pay the February 2010 invoice"
          end
          
          current_url.should =~ %r(^http://[^/]+/suspended$)
          
          @worker.work_off # delayed unsuspend is done
          
          visit '/suspended'
          current_url.should =~ %r(^http://[^/]+/sites$)
        end
      end
      
    end
  end
  
end