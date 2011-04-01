require 'spec_helper'

feature "Invoice actions:" do

  background do
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
    scenario "paid invoice with VAT" do
      @current_user.update_attribute(:country, 'CH')
      site = Factory(:site_with_invoice, plan_id: @paid_plan.id, user: @current_user, hostname: 'rymai.com')
      @invoice = site.last_invoice

      visit invoice_path(@invoice)

      page.should have_content("Jilion / Jime SA")
      page.should have_content("Invoice ID: #{@invoice.reference.upcase}")
      page.should have_content("Status:")
      page.should have_content("Paid on #{I18n.l(@invoice.paid_at, :format => :minutes_timezone)}")

      page.should have_content(site.hostname)
      page.should have_content(site.token)
      page.should have_content("Payment info:")
      page.should have_content("Card type: Visa")
      page.should have_content("Card no.: XXXXXXXXXXXX-1111")

      page.should have_content("Bill to:")
      page.should have_content("#{@invoice.customer_full_name} (#{@invoice.customer_email})")
      # page.should have_content("#{@invoice.customer_country}")

      page.should have_content("Period: #{I18n.l(site.plan_cycle_started_at, :format => :d_b_Y)} - #{I18n.l(site.plan_cycle_ended_at, :format => :d_b_Y)}")
      page.should have_content("VAT 8%:")
      page.should have_content("$#{@invoice.vat_amount / 100.0}")
      page.should have_content("$#{@invoice.amount / 100.0}")
    end

    scenario "upgrade paid invoice with discount" do
      @current_user.update_attribute(:created_at, Time.utc(2010,10,10))
      @current_user.update_attribute(:country, 'US')
      site = Factory(:site_with_invoice, plan_id: @paid_plan.id, user: @current_user, hostname: 'rymai.com')
      VCR.use_cassette('ogone/visa_payment_generic') do
        site.update_attributes(plan_id: @custom_plan.token, user_attributes: { 'current_password' => '123456' })
      end
      site.apply_pending_plan_changes
      invoice = site.last_invoice

      visit invoice_path(invoice)

      page.should have_content("Jilion / Jime SA")
      page.should have_content("Invoice ID: #{invoice.reference.upcase}")
      page.should have_content("Status:")
      page.should have_content("Paid on #{I18n.l(invoice.paid_at, :format => :minutes_timezone)}")

      page.should have_content(site.hostname)
      page.should have_content(site.token)
      page.should have_content("Payment info:")
      page.should have_content("Card type: Visa")
      page.should have_content("Card no.: XXXXXXXXXXXX-1111")

      page.should have_content("Bill to:")
      page.should have_content("#{invoice.customer_full_name} (#{invoice.customer_email})")

      page.should have_content("Period: #{I18n.l(site.plan_cycle_started_at, :format => :d_b_Y)} - #{I18n.l(site.plan_cycle_ended_at, :format => :d_b_Y)}")
      page.should have_content("(-20% beta discount)")
      page.should have_content("$160")
      page.should have_content("-$8.0")
      page.should have_content("$#{invoice.amount / 100.0}")
    end
  end

  feature "retry failed invoice" do
    scenario "with 0 failed invoices" do
      @current_user.update_attribute(:created_at, Time.utc(2010,10,10))
      @site = Factory(:site_with_invoice, plan_id: @dev_plan.id, user: @current_user, hostname: 'rymai.com')

      visit "/sites"
      click_link "Edit rymai.com"
      click_link "Invoices"

      current_url.should =~ %r(http://[^/]+/sites/#{@site.to_param}/invoices)
      page.should have_content(@site.hostname)

      page.should have_no_content('failed invoices for a total')
    end

    # pending because site.plan_cycle_ended_at is nil even after the redirection ... :(
    pending "with 1 or more failed invoices" do
      @current_user.update_attribute(:created_at, Time.utc(2010,10,10))
      @site = Factory(:site_with_invoice, plan_id: @paid_plan.id, user: @current_user, hostname: 'google.com')
      @invoice = @site.last_invoice
      @site.pending_plan_started_at = Time.now.utc
      @site.pending_plan_cycle_started_at = Time.now.utc
      @site.pending_plan_cycle_ended_at = Time.now.utc
      @site.save!(validate: false)
      
      @invoice.update_attributes(state: 'failed', last_failed_at: Time.now.utc)
      @invoice.should be_failed
      @invoice.last_transaction.update_attributes(state: 'failed', error: "Credit card refused")

      visit "/sites/#{@site.to_param}/invoices"

      page.should have_content("You have 1 failed invoices for a total of $#{@invoice.amount / 100.0}.")

      VCR.use_cassette('ogone/visa_payment_acceptance') { click_button I18n.t('site.invoices.retry_invoices') }

      @site.invoices.failed.should be_empty
      
      current_url.should =~ %r(http://[^/]+/sites/#{@site.to_param}/invoices)

      page.should have_content(@site.hostname)

      page.should have_content('Past invoices')
      page.should have_content("Paid on #{I18n.l(@site.invoices.paid.last.paid_at, :format => :minutes_timezone)}")
      page.should have_no_content('failed invoices for a total')
    end
  end

end
