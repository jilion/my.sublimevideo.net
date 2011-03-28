require 'spec_helper'

feature "Invoice actions:" do

  background do
    create_plans
    sign_in_as :user
  end

  feature "index" do
    scenario "views site invoices (with 0 past invoices)" do
      site = Factory(:site, plan_id: @dev_plan.id, user: @current_user, hostname: 'rymai.com')

      visit "/sites"
      click_link "Edit rymai.com"
      click_link "Invoices"

      current_url.should =~ %r(http://[^/]+/sites/#{site.token}/invoices)
      page.should have_content('rymai.com')

      page.should have_content('No invoices')
    end

    scenario "views site invoices (with 1 invoice and 1 next invoice)" do
      site = Factory(:site_with_invoice, plan_id: @paid_plan.id, user: @current_user, hostname: 'rymai.com')

      visit "/sites"
      click_link "Edit rymai.com"
      click_link "Invoices"

      current_url.should =~ %r(http://[^/]+/sites/#{site.token}/invoices)
      page.should have_content('rymai.com')

      page.should have_content('Next invoice')
      page.should have_content("$#{@paid_plan.price / 100}")
      page.should have_content("on #{I18n.l(site.plan_cycle_ended_at.tomorrow, :format => :d_b_Y)}")

      page.should have_content('Past invoices')
      page.should have_content("Paid on #{I18n.l(site.last_invoice.paid_at, :format => :minutes_timezone)}")
    end

    scenario "views site invoices with 1 failed invoice" do
      site = Factory(:site_with_invoice, plan_id: @paid_plan.id, user: @current_user, hostname: 'rymai.com')
      @invoice = site.last_invoice
      @invoice.update_attributes(state: 'failed', last_failed_at: Time.now.utc)
      @invoice.last_transaction.update_attribute(:error, "Credit card refused")

      visit "/sites"
      click_link "Edit rymai.com"
      click_link "Invoices"

      current_url.should =~ %r(http://[^/]+/sites/#{site.token}/invoices)
      page.should have_content('rymai.com')

      page.should have_content('Next invoice')
      page.should have_content("$#{@paid_plan.price / 100}")
      page.should have_content("on #{I18n.l(site.plan_cycle_ended_at.tomorrow, :format => :d_b_Y)}")

      page.should have_content('Past invoices')
      page.should have_content("Payment failed on #{I18n.l(@invoice.last_failed_at, :format => :minutes_timezone)}")
      page.should have_content("with the following error:")
      page.should have_content("\"Credit card refused\".")
    end

    scenario "views site invoices with 1 failed invoice having the 3d secure html as the error" do
      site = Factory(:site_with_invoice, plan_id: @paid_plan.id, user: @current_user, hostname: 'rymai.com')
      @invoice = site.last_invoice
      @invoice.update_attributes(state: 'failed', last_failed_at: Time.now.utc)
      @invoice.last_transaction.update_attribute(:error, "<html>secure.ogone...</html>")

      visit "/sites"
      click_link "Edit rymai.com"
      click_link "Invoices"

      current_url.should =~ %r(http://[^/]+/sites/#{site.token}/invoices)
      page.should have_content('rymai.com')

      page.should have_content('Next invoice')
      page.should have_content("$#{@paid_plan.price / 100}")
      page.should have_content("on #{I18n.l(site.plan_cycle_ended_at.tomorrow, :format => :d_b_Y)}")

      page.should have_content('Past invoices')
      page.should have_content("Payment failed on #{I18n.l(@invoice.paid_at, :format => :minutes_timezone)}.")
      page.should have_no_content("with the following error")
    end
  end

  feature "show" do
    scenario "paid invoice" do
      @current_user.update_attribute(:country, 'CH')
      site = Factory(:site_with_invoice, plan_id: @paid_plan.id, user: @current_user, hostname: 'rymai.com')
      @invoice = site.last_invoice

      visit invoice_path(@invoice)

      page.should have_content("Jilion / Jime SA")
      page.should have_content("Invoice ID: #{@invoice.reference.upcase}")
      page.should have_content("Status:")
      page.should have_content("Paid on #{I18n.l(@invoice.paid_at, :format => :minutes_timezone)}")

      page.should have_content("rymai.com")
      page.should have_content("Payment info:")
      page.should have_content("Card type: Visa")
      page.should have_content("Card no.: XXXXXXXXXXXX-1111")

      page.should have_content("Bill to:")
      page.should have_content("#{@invoice.customer_full_name} (#{@invoice.customer_email})")
      page.should have_content("#{@invoice.customer_country}")

      page.should have_content("Period: #{I18n.l(site.plan_cycle_started_at, :format => :d_b_Y)} - #{I18n.l(site.plan_cycle_ended_at, :format => :d_b_Y)}")
      page.should have_content("VAT 8%:")
      page.should have_content("$#{@invoice.vat_amount / 100.0}")
      page.should have_content("$#{@invoice.amount / 100.0}")
    end
  end

  feature "retry failed invoice" do
    scenario "with 0 failed invoices" do
      site = Factory(:site_with_invoice, plan_id: @dev_plan.id, user: @current_user, hostname: 'rymai.com')

      visit "/sites"
      click_link "Edit rymai.com"
      click_link "Invoices"

      current_url.should =~ %r(http://[^/]+/sites/#{site.token}/invoices)
      page.should have_content('rymai.com')

      page.should have_no_content('failed invoices for a total')
    end

    pending "with 1 or more failed invoices" do # FUCK I DON'T GET IT!!!!!!
      site = Factory(:site_with_invoice, plan_id: @paid_plan.id, user: @current_user, hostname: 'rymai.com')
      @invoice = site.last_invoice
      @invoice.update_attributes(state: 'failed', last_failed_at: Time.now.utc)
      @invoice.last_transaction.update_attribute(:error, "Credit card refused")

      visit "/sites/#{site.token}/invoices"

      page.should have_content("You have 1 failed invoices for a total of $#{@invoice.amount / 100.0}.")
      
      puts "before submit : #{site.inspect}"
      VCR.use_cassette('ogone/visa_payment_acceptance') { click_button I18n.t('site.invoices.retry_failed_invoices') }
      puts "after submit : #{site.inspect}"
      save_and_open_page
      current_url.should =~ %r(http://[^/]+/sites/#{site.token}/invoices)

      page.should have_content('rymai.com')

      page.should have_content('Past invoices')
      page.should have_content("Paid on #{I18n.l(@invoice.paid_at, :format => :minutes_timezone)}")
      page.should have_no_content('failed invoices for a total')
    end
  end

end
