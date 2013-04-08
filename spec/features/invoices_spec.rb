require 'spec_helper'
include ActionView::Helpers::NumberHelper
include ApplicationHelper

feature "Site invoices page" do

  context "user has a credit card" do
    background do
      sign_in_as :user
    end

    describe "navigation and content presence verification" do
      background do
        @site = build(:site, user: @current_user, hostname: 'rymai.com')
        SiteManager.new(@site).create
        create(:invoice, site: @site)
        go 'my', "/sites/#{@site.to_param}/edit"
      end

      scenario "'Invoice' tab is visible and reachable" do
        click_link "Invoices"

        current_url.should == "http://my.sublimevideo.dev/sites/#{@site.to_param}/invoices"
        page.should have_content 'rymai.com'
        page.should have_no_content 'No invoices'
      end
    end

    context "site with invoices" do
      background do
        @site = build(:site, user: @current_user, hostname: 'rymai.com')
        SiteManager.new(@site).create
        @invoice = create(:paid_invoice, site: @site)
        @invoice.should be_valid
        go 'my', "/sites/#{@site.to_param}/edit"
      end

      scenario "'Invoice' tab is visible and reachable" do
        click_link "Invoices"

        current_url.should == "http://my.sublimevideo.dev/sites/#{@site.to_param}/invoices"
        page.should have_content 'rymai.com'
        page.should have_no_content 'No invoices'
        page.should have_content 'Past invoices'
        within '.past_invoices' do
          page.should have_content "#{display_amount(@invoice.amount)} on #{I18n.l(@invoice.created_at, format: :d_b_Y)}"
          page.should have_content "Status: Paid on #{I18n.l(@site.last_invoice.paid_at, format: :minutes_timezone)}"
        end
      end
    end

    context "site in paid plan with 1 failed invoice" do
      background do
        @site = build(:site, user: @current_user, hostname: 'rymai.com')
        SiteManager.new(@site).create
        @invoice = create(:failed_invoice, site: @site)
        @transaction = create(:transaction, invoices: [@invoice], error: 'Credit card refused')
        go 'my', "/sites/#{@site.to_param}/invoices"
      end

      scenario "displays a notice" do
        page.should have_content "You have 1 failed invoice for a total of #{display_amount(@invoice.amount)}"
        page.should have_content "If necessary, update your credit card and then retry the payment via the button below."

        within '.past_invoices' do
          page.should have_content "#{display_amount(@invoice.amount)} on #{I18n.l(@invoice.created_at, format: :d_b_Y)}"
          page.should have_content "Status: Payment failed on #{I18n.l(@invoice.last_failed_at, format: :minutes_timezone)}"
          page.should have_content "with the following error: \"Credit card refused\"."
        end
      end

      describe "retry the payment" do
        scenario "it is possible to retry the payment" do
          VCR.use_cassette('ogone/visa_payment_acceptance') { click_button I18n.t('invoice.pay_invoices_above') }

          @site.invoices.failed.should be_empty

          current_url.should == "http://my.sublimevideo.dev/sites/#{@site.to_param}/invoices"

          page.should have_no_content 'failed invoices for a total'
          within '.past_invoices' do
            page.should have_content "#{display_amount(@invoice.amount)} on #{I18n.l(@invoice.created_at, format: :d_b_Y)}"
            page.should have_content "Status: Paid on #{I18n.l(@invoice.reload.paid_at, format: :minutes_timezone)}"
            page.should have_no_content "Status: Payment failed"
          end
        end
      end

    end

    context "site in paid plan with 1 failed invoice having the 3d secure html as the error" do
      background do
        @site = build(:site, user: @current_user, hostname: 'rymai.com')
        SiteManager.new(@site).create
        @invoice = create(:failed_invoice, site: @site)
        @transaction = create(:transaction, invoices: [@invoice], error: '<html>secure.ogone...</html>')
        go 'my', "/sites/#{@site.to_param}/invoices"
      end

      scenario "displays a notice" do
        page.should have_content "You have 1 failed invoice for a total of $#{@invoice.amount / 100.0}"
        page.should have_content "If necessary, update your credit card and then retry the payment via the button below."

        within '.past_invoices' do
          page.should have_content "#{display_amount(@invoice.amount)} on #{I18n.l(@invoice.created_at, format: :d_b_Y)}"
          page.should have_content "Status: Payment failed on #{I18n.l(@invoice.last_failed_at, format: :minutes_timezone)}"
          page.should have_no_content "with the following error"
        end
      end
    end

    context "site in paid plan with 1 failed invoice and 1 failed invoice for another site" do
      background do
        @site = build(:site, user: @current_user, hostname: 'rymai.com')
        SiteManager.new(@site).create
        @invoice1 = create(:failed_invoice, site: @site, last_failed_at: 2.days.ago)
        @transaction = create(:transaction, invoices: [@invoice1], error: 'Credit card refused')
        @invoice2 = create(:failed_invoice, site: @site)
         @transaction = create(:transaction, invoices: [@invoice2], error: 'Authorization refused')
        go 'my', "/sites/#{@site.to_param}/invoices"
      end

      scenario "displays a notice" do
        page.should have_content "You have 2 failed invoices for a total of #{display_amount(@invoice1.amount + @invoice2.amount)}"
        page.should have_content "If necessary, update your credit card and then retry the payment via the button below."

        within '.past_invoices' do
          page.should have_content "#{display_amount(@invoice1.amount)} on #{I18n.l(@invoice1.created_at, format: :d_b_Y)}"
          page.should have_content "Status: Payment failed on #{I18n.l(@invoice1.last_failed_at, format: :minutes_timezone)}"
          page.should have_content "with the following error: \"Credit card refused\"."

          page.should have_content "#{display_amount(@invoice2.amount)} on #{I18n.l(@invoice2.created_at, format: :d_b_Y)}"
          page.should have_content "Status: Payment failed on #{I18n.l(@invoice2.last_failed_at, format: :minutes_timezone)}"
          page.should have_content "with the following error: \"Authorization refused\"."
        end
      end
    end
  end

  context "user has no credit card" do
    background do
      sign_in_as :user, without_cc: true
      @site = build(:site, user: @current_user, hostname: 'rymai.com')
      SiteManager.new(@site).create
      @invoice = create(:failed_invoice, site: @site)
      @transaction = create(:transaction, invoices: [@invoice], error: 'Credit card refused')
      go 'my', "/sites/#{@site.to_param}/invoices"
    end

    scenario "displays a notice" do
      page.should have_content "You have 1 failed invoice for a total of #{display_amount(@invoice.amount)}"
      page.should have_content "Please add a valid credit card and then retry the payment here."

      within '.past_invoices' do
        page.should have_content "#{display_amount(@invoice.amount)} on #{I18n.l(@invoice.created_at, format: :d_b_Y)}"
        page.should have_content "Status: Payment failed on #{I18n.l(@invoice.last_failed_at, format: :minutes_timezone)}"
        page.should have_content "with the following error: \"Credit card refused\"."
      end
    end
  end

  context "user credit card is expired" do
    background do
      sign_in_as :user, cc_expire_on: 2.years.ago
      @current_user.should be_cc_expired
      @site = build(:site, user: @current_user, hostname: 'rymai.com')
      SiteManager.new(@site).create
      @invoice = create(:failed_invoice, site: @site)
      @transaction = create(:transaction, invoices: [@invoice], error: 'Credit card refused')
      go 'my', "/sites/#{@site.to_param}/invoices"
    end

    scenario "displays a notice" do
      page.should have_content "You have 1 failed invoice for a total of #{display_amount(@invoice.amount)}"
      page.should have_content "Your credit card is expired"
      page.should have_content "Please update your credit card and then retry the payment here."

      within('.past_invoices') do
        page.should have_content "#{display_amount(@invoice.amount)} on #{I18n.l(@invoice.created_at, format: :d_b_Y)}"
        page.should have_content "Status: Payment failed on #{I18n.l(@invoice.last_failed_at, format: :minutes_timezone)}"
        page.should have_content "with the following error: \"Credit card refused\"."
      end
    end
  end

end

feature "Site invoice page" do

  context "invoice doesn't have VAT" do
    background do
      sign_in_as :user
    end

    context "normal invoice" do
      background do
        @site = build(:site, user: @current_user, hostname: 'rymai.com')
        SiteManager.new(@site).create

        @invoice = build(:invoice, site: @site, vat_rate: 0, vat_amount: 0)
        @invoice.invoice_items << build(:addon_plan_invoice_item, item: @stats_addon_plan_2)
        @invoice.save!
        @transaction = create(:transaction, invoices: [@invoice])
        @invoice.succeed!

        go 'my', "/invoices/#{@invoice.reference}"
      end

      scenario "displays well" do
        page.should have_content "Jilion SA"
        page.should have_content "Invoice ID: #{@invoice.reference.upcase}"
        page.should have_content "Status:"
        page.should have_content "Paid on #{I18n.l(@invoice.paid_at, format: :minutes_timezone)}"

        page.should have_content @site.hostname
        page.should have_content @site.token
        page.should have_content "Payment info:"
        page.should have_content "Card type: #{I18n.t('user.credit_card.type.visa')}"
        page.should have_content "Card no.: XXXXXXXXXXXX-1111"

        page.should have_content "Bill To"
        @invoice.customer_billing_address.split("\n").each do |address_part|
          page.should have_content(address_part)
        end

        page.should have_content "#{I18n.l(@invoice.invoice_items[0].started_at, format: :d_b_Y)} - #{I18n.l(@invoice.invoice_items[0].ended_at, format: :d_b_Y)}"
        page.should have_content display_amount(@invoice.invoice_items[0].price)

        page.should have_content "VAT 0%:"
        page.should have_content display_amount(0)

        page.should have_content display_amount(@invoice.amount)
      end
    end

    context "upgrade invoice" do
      background do
        @site = build(:site, user: @current_user, hostname: 'rymai.com')
        SiteManager.new(@site).create
        @invoice = build(:invoice, site: @site)
        @plan_invoice_item1 = build(:plan_invoice_item, amount: -1000)
        @plan_invoice_item2 = build(:plan_invoice_item, amount: 1000)
        @invoice.invoice_items << @plan_invoice_item1 << @plan_invoice_item2
        @invoice.save!

        go 'my', "/invoices/#{@invoice.reference}"
      end

      scenario "includes a line for the deducted plan" do
        page.should have_content("#{I18n.l(@plan_invoice_item2.started_at, format: :d_b_Y)} - #{I18n.l(@plan_invoice_item2.ended_at, format: :d_b_Y)}")
        page.should have_content("-$10.00")
      end
    end

    context "invoice has balance deduction" do
      background do
        @site = build(:site, user: @current_user, hostname: 'rymai.com')
        SiteManager.new(@site).create
        @invoice = create(:invoice, site: @site, balance_deduction_amount: 20000).tap { |i|
          create(:addon_plan_invoice_item, item: @stats_addon_plan_2, invoice: i)
        }

        go 'my', "/invoices/#{@invoice.reference}"

        @invoice = @site.last_invoice
      end

      scenario "shows a special line" do
        page.should have_content "From your balance:"
        page.should have_content display_amount(@invoice.balance_deduction_amount)
      end
    end

    context "invoice has a deal discount" do
      background do
        @site = build(:site, user: @current_user, hostname: 'rymai.com')
        SiteManager.new(@site).create
        @invoice = create(:invoice, site: @site).tap { |i|
          create(:plan_invoice_item, invoice: i)
        }
        @deal = create(:deal, value: 0.3, name: 'Foo bar Deal')
        @invoice.plan_invoice_items.order(:id).first.update_attribute(:discounted_percentage, 0.3)
        @invoice.plan_invoice_items.order(:id).first.update_attribute(:deal_id, @deal.id)

        go 'my', "/invoices/#{@invoice.reference}"
      end

      scenario "displays a note" do
        page.should have_content "(-30% promotional discount)"
      end
    end

    context "invoice has beta discount" do
      background do
        @site = build(:site, user: @current_user, hostname: 'rymai.com')
        SiteManager.new(@site).create
        @invoice = create(:invoice, site: @site).tap { |i|
          create(:plan_invoice_item, invoice: i)
        }

        @invoice.plan_invoice_items.order(:id).first.update_attribute(:discounted_percentage, 0.2)

        go 'my', "/invoices/#{@invoice.reference}"
      end

      scenario "displays a note" do
        page.should have_content "(-20% beta discount)"
      end
    end
  end

  context "user has VAT" do
    background do
      sign_in_as :user, billing_country: 'CH'
      @site = build(:site, user: @current_user, hostname: 'rymai.com')
      SiteManager.new(@site).create
      @invoice = create(:invoice, site: @site).tap { |i|
        create(:plan_invoice_item, invoice: i)
      }

      go 'my', "/invoices/#{@invoice.reference}"
    end

    scenario "shows a special line" do
      page.should have_content "VAT 8%:"
      page.should have_content display_amount(@invoice.vat_amount)
    end
  end

end
