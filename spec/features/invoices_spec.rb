require 'spec_helper'
include ActionView::Helpers::NumberHelper
include ApplicationHelper

feature "Site invoices page" do

  context "user has a credit card", :vcr do
    background { sign_in_as :user_with_aliased_cc }

    describe "navigation and content presence verification" do
      background do
        @site = build(:site, user: @current_user, hostname: 'rymai.com')
        SiteManager.new(@site).create
        create(:invoice, site: @site)
        go 'my', "/sites/#{@site.to_param}/edit"
      end

      scenario "'Invoice' tab is visible and reachable" do
        click_link "Invoices"

        expect(current_url).to eq("http://my.sublimevideo.dev/sites/#{@site.to_param}/invoices")
        expect(page).to have_content 'rymai.com'
        expect(page).to have_no_content 'No invoices'
      end
    end

    context "site with invoices" do
      background do
        @site = build(:site, user: @current_user, hostname: 'rymai.com')
        SiteManager.new(@site).create
        @invoice = create(:paid_invoice, site: @site)
        expect(@invoice).to be_valid
        go 'my', "/sites/#{@site.to_param}/edit"
      end

      scenario "'Invoice' tab is visible and reachable" do
        click_link "Invoices"

        expect(current_url).to eq("http://my.sublimevideo.dev/sites/#{@site.to_param}/invoices")
        expect(page).to have_content 'rymai.com'
        expect(page).to have_no_content 'No invoices'
        expect(page).to have_content 'Paid invoices'
        within '.past_invoices' do
          expect(page).to have_content "#{display_amount(@invoice.amount)} on #{I18n.l(@invoice.created_at, format: :d_b_Y)}"
          expect(page).to have_content "Status: Paid on #{I18n.l(@site.last_invoice.paid_at, format: :minutes_timezone)}"
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

      describe "retry the payment" do
        scenario "it is possible to retry the payment" do
          click_button I18n.t('invoice.pay_outstanding_invoices', count: 1)

          expect(@site.invoices.with_state('failed')).to be_empty

          expect(current_url).to eq("http://my.sublimevideo.dev/sites/#{@site.to_param}/invoices")

          expect(page).to have_no_content 'failed invoices for a total'
          within '.past_invoices' do
            expect(page).to have_content "#{display_amount(@invoice.amount)} on #{I18n.l(@invoice.created_at, format: :d_b_Y)}"
            expect(page).to have_content "Status: Paid on #{I18n.l(@invoice.reload.paid_at, format: :minutes_timezone)}"
            expect(page).to have_no_content "Status: Payment failed"
          end
        end
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
        expect(page).to have_content "Jilion SA"
        expect(page).to have_content "Invoice ID: #{@invoice.reference.upcase}"
        expect(page).to have_content "Status:"
        expect(page).to have_content "Paid on #{I18n.l(@invoice.paid_at, format: :minutes_timezone)}"

        expect(page).to have_content @site.hostname
        expect(page).to have_content @site.token
        expect(page).to have_content "Payment info:"
        expect(page).to have_content "Card type: #{I18n.t('user.credit_card.type.visa')}"
        expect(page).to have_content "Card no.: XXXXXXXXXXXX-1111"

        expect(page).to have_content "Bill To"
        @invoice.customer_billing_address.split("\n").each do |address_part|
          expect(page).to have_content(address_part)
        end

        expect(page).to have_content "#{I18n.l(@invoice.invoice_items[0].started_at, format: :d_b_Y)} - #{I18n.l(@invoice.invoice_items[0].ended_at, format: :d_b_Y)}"
        expect(page).to have_content display_amount(@invoice.invoice_items[0].price)

        expect(page).to have_content "VAT 0%:"
        expect(page).to have_content display_amount(0)

        expect(page).to have_content display_amount(@invoice.amount)
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
        expect(page).to have_content "From your balance:"
        expect(page).to have_content display_amount(@invoice.balance_deduction_amount)
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
        expect(page).to have_content "(-30% promotional discount)"
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
        expect(page).to have_content "(-20% beta discount)"
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
      expect(page).to have_content "VAT 8%:"
      expect(page).to have_content display_amount(@invoice.vat_amount)
    end
  end

end
