# coding: utf-8
require 'spec_helper'

feature "Terms page" do

  scenario "/terms" do
    go 'my', 'terms'
    page.should have_content('Terms & Conditions')
  end

end

feature "Privacy page" do

  scenario "/privacy" do
    go 'my', 'privacy'
    page.should have_content('Privacy Policy')
  end

end

feature "Help page" do

  describe "Access the help page" do
    context "When the user is logged-in" do
      background do
        sign_in_as :user
      end

      scenario "can access the page directly" do
        go 'my', '/help'
        current_url.should eq "http://my.sublimevideo.dev/help"
      end

      scenario "can access the page via a link in the menu" do
        within '#menu' do
          click_link "help"
        end
        current_url.should eq "http://my.sublimevideo.dev/help"
      end

      scenario "redirect /feedback and /support" do
        go 'my', '/support'
        current_url.should eq "http://my.sublimevideo.dev/help"

        go 'my', '/feedback'
        current_url.should eq "http://my.sublimevideo.dev/help"
      end
    end
  end

  context "user has the 'forum' support level" do
    background do
      sign_in_as :user
      create(:site, user: @current_user, plan_id: @free_plan.id)
      go 'my', '/help'
    end

    describe "new" do
      scenario "doesn't have access to the form" do
        page.should have_no_content 'use the form below'
        page.should have_no_selector 'form.new_ticket'
      end
    end
  end

  context "user has the 'email' support level" do
    background do
      sign_in_as :user
      create(:site, user: @current_user, plan_id: @paid_plan.id)
      go 'my', '/help'
    end

    describe "new" do
      scenario "has access to the form" do
        page.should have_content 'use the form below'
        page.should have_selector 'form.new_ticket'
      end

      scenario "submit a valid ticket" do
        fill_in "Subject", with: "I have a request!"
        fill_in "Message", with: "I have a request this is a long text!"
        expect { click_button "Send" }.to change(Delayed::Job.where { handler =~ "%post_ticket%" }, :count).by(1)

        page.should have_content I18n.t('flash.tickets.create.notice')

        CampaignMonitor.stub(:subscriber)
        VoxcastCDN.stub(:purge)
        Pusher.stub(:[])
        VCR.use_cassette("ticket/post_ticket") do
          expect { @worker.work_off }.to change(Delayed::Job.where { handler =~ "%post_ticket%" }, :count).by(-1)
        end
        @current_user.reload.zendesk_id.should be_present
      end

      scenario "submit a ticket with an invalid subject" do
        fill_in "Subject", with: ""
        fill_in "Message", with: "I have a request this is a long text!"
        click_button "Send"

        current_url.should eq "http://my.sublimevideo.dev/help"
        page.should have_content "Subject can't be blank"
        page.should have_no_content I18n.t('flash.tickets.create.notice')
        Delayed::Job.last.should_not eq 'Class#post_ticket'
      end

      scenario "submit a ticket with an invalid message" do
        fill_in "Subject", with: "I have a request!"
        fill_in "Message", with: ""
        click_button "Send"

        current_url.should eq "http://my.sublimevideo.dev/help"
        page.should have_content "Message can't be blank"
        page.should have_no_content I18n.t('flash.tickets.create.notice')
        Delayed::Job.last.should_not eq 'Class#post_ticket'
      end
    end
  end

end

feature "Suspended page" do

  context "logged-in user" do
    background do
      create_plans
      sign_in_as :user
    end

    context "with a non-suspended user" do
      scenario "/suspended" do
        create_plans
        go 'my', 'suspended'

        current_url.should eq "http://my.sublimevideo.dev/sites/new"
        page.should have_no_content 'Your account is suspended'
      end
    end

    context "with a suspended user" do
      background do
        @site  = create(:site, user: @current_user)
        @site.pending_plan_started_at = Time.now.utc
        @site.pending_plan_cycle_started_at = Time.now.utc
        @site.pending_plan_cycle_ended_at = Time.now.utc
        @site.save!(validate: false)
        @invoice = create(:invoice, site: @site, state: 'failed', last_failed_at: Time.utc(2010,2,10), amount: 1990)
        @transaction = create(:transaction, invoices: [@invoice], state: 'failed', error: "Credit Card expired")
        @current_user.suspend
        @site.reload.should be_suspended
        @current_user.reload.should be_suspended
      end

      scenario "can't visit the edit account page" do
        go 'my', 'account'

        current_url.should eq "http://my.sublimevideo.dev/suspended"
      end

      scenario "can visit the edit credit card page" do
        go 'my', 'account/billing/edit'

        current_url.should eq "http://my.sublimevideo.dev/account/billing/edit"
      end

      scenario "and an expired credit card, should be able to visit the credit card form page" do
        @current_user.cc_expire_on = 1.month.ago
        @current_user.save(validate: false)
        @current_user.reload.should be_cc_expired
        go 'my', 'sites'

        current_url.should eq "http://my.sublimevideo.dev/suspended"

        page.should have_content "Your account is suspended"
        page.should have_content "Your credit card is expired"
        page.should have_content "Visa ending in 1111"
        page.should have_content "Update credit card"
        page.should have_content "Please pay the following invoice in order to reactivate your account:"
        page.should have_content "$19.90 on #{I18n.l(@invoice.created_at, :format => :d_b_Y)}."
        page.should have_content "Payment failed on #{I18n.l(@invoice.last_failed_at, :format => :minutes_timezone)} with the following error:"
        page.should have_content "\"#{@invoice.last_transaction.error}\""

        click_link "Update credit card"

        current_url.should eq "http://my.sublimevideo.dev/account/billing/edit"
      end

      scenario "and a valid credit card with 1 or more failed invoices" do
        ActionMailer::Base.deliveries.clear
        go 'my', 'suspended'

        current_url.should eq "http://my.sublimevideo.dev/suspended"

        VCR.use_cassette('ogone/visa_payment_acceptance') { click_button I18n.t('invoice.retry_invoices') }

        current_url.should eq "http://my.sublimevideo.dev/sites"

        @site.invoices.failed.should be_empty
        @site.reload.should be_active
        @current_user.reload.should be_active

        first_delivery = ActionMailer::Base.deliveries.first
        first_delivery.to.should eq [@current_user.email]
        first_delivery.subject.should eq "Your account has been reactivated"
        first_delivery.body.encoded.should include "Your account has been reactivated."

        last_delivery = ActionMailer::Base.deliveries.last
        last_delivery.to.should eq [@current_user.email]
        last_delivery.subject.should eq "Payment approved"
        last_delivery.body.encoded.should include "Your latest SublimeVideo payment has been approved."

        go 'my', 'suspended'
        current_url.should eq "http://my.sublimevideo.dev/sites"
      end

    end
  end
end