require 'spec_helper'

feature "Plan edit" do
  background do
    sign_in_as :user
    @premium_month = Plan.create(name: "premium", cycle: "month", video_views: 200_000, price: 4990)
    @premium_year = Plan.create(name: "premium", cycle: "year", video_views: 200_000, price: 49900)
  end

  scenario "view with a free plan without hostname" do
    site = create(:site, user: @current_user, plan_id: @free_plan.id, hostname: nil)

    go 'my', "/sites/#{site.to_param}/plan/edit"

    current_url.should == "http://my.sublimevideo.dev/sites/#{site.to_param}/plan/edit"
    page.should have_content "add a hostname"
  end

  scenario "update trial plan to paid plan" do
    site = create(:site, user: @current_user, plan_id: @trial_plan.id)

    go 'my', "/sites/#{site.to_param}/plan/edit"

    choose "plan_plus_month"
    VCR.use_cassette('ogone/visa_payment_generic') do
      expect { click_button "Update plan" }.to change(@current_user.invoices, :count)
    end

    site.reload
    site.plan.should eq @paid_plan
    site.invoices.last.should be_paid
    site.plan_id.should eq Plan.find_by_name_and_cycle("plus", "month").id
    site.pending_plan_id.should be_nil
    site.first_paid_plan_started_at.should be_present
    site.plan_started_at.should be_present
    site.plan_cycle_started_at.should be_present
    site.plan_cycle_ended_at.should be_present
    site.pending_plan_started_at.should be_nil
    site.pending_plan_cycle_started_at.should be_nil
    site.pending_plan_cycle_ended_at.should be_nil

    current_url.should eq "http://my.sublimevideo.dev/sites"
    page.should have_content(site.plan.title)
  end

  scenario "update free plan to paid plan" do
    site = create(:site, user: @current_user, plan_id: @free_plan.id)

    go 'my', "/sites/#{site.to_param}/plan/edit"

    choose "plan_plus_month"
    VCR.use_cassette('ogone/visa_payment_generic') do
      expect { click_button "Update plan" }.to change(@current_user.invoices, :count)
    end

    site.reload
    site.plan.should eq @paid_plan
    site.invoices.last.should be_paid
    site.plan_id.should eq Plan.find_by_name_and_cycle("plus", "month").id
    site.pending_plan_id.should be_nil
    site.first_paid_plan_started_at.should be_present
    site.plan_started_at.should be_present
    site.plan_cycle_started_at.should be_present
    site.plan_cycle_ended_at.should be_present
    site.pending_plan_started_at.should be_nil
    site.pending_plan_cycle_started_at.should be_nil
    site.pending_plan_cycle_ended_at.should be_nil

    current_url.should eq "http://my.sublimevideo.dev/sites"
    page.should have_content(site.plan.title)
  end

  scenario "view with a free plan without hostname" do
    site = create(:site, user: @current_user, plan_id: @free_plan.id, hostname: nil)

    go 'my', "/sites/#{site.to_param}/plan/edit"

    current_url.should =~ %r(http://[^/]+/sites/#{site.token}/plan/edit$)
    page.should have_content("add a hostname")
  end

  scenario "update paid plan to free plan" do
    site = create(:site_with_invoice, user: @current_user, plan_id: @paid_plan.id)

    go 'my', "/sites/#{site.to_param}/plan/edit"

    choose "plan_free"
    click_button "Update plan"

    has_checked_field?("plan_free").should be_true
    has_unchecked_field?("plan_plus_month").should be_true

    fill_in "Password", with: "123456"
    click_button "Done"

    site.reload

    current_url.should == "http://my.sublimevideo.dev/sites"
    page.should have_content("#{site.plan.title} plan => #{site.next_cycle_plan.title} plan")

    click_link "#{site.plan.title} plan => #{site.next_cycle_plan.title} plan"

    page.should have_content("Your new #{site.next_cycle_plan.title} plan will automatically start on #{I18n.l(site.plan_cycle_ended_at.tomorrow.midnight, format: :named_date).squeeze(' ')}.")
  end

  scenario "update free plan to paid plan" do
    site = create(:site_with_invoice, user: @current_user, plan_id: @premium_month.id)
    site.plan_id = @free_plan.id
    site.skip_password(:save!)
    Timecop.travel(2.months.from_now) { site.prepare_pending_attributes; site.apply_pending_attributes }
    site.reload.plan.should eql @free_plan

    go 'my', "/sites/#{site.to_param}/plan/edit"

    VCR.use_cassette('ogone/visa_payment_generic') do
      choose "plan_plus_month"
      click_button "Update plan"
    end

    site.reload.plan.should eql @paid_plan

    current_url.should == "http://my.sublimevideo.dev/sites"
    page.should have_content(site.plan.title)

    click_link site.plan.title
  end

  scenario "update paid plan to paid plan and using registered credit card" do
    site = create(:site_with_invoice, user: @current_user, plan_id: @premium_month.id)
    site.plan.should eql @premium_month
    site.first_paid_plan_started_at.should be_present
    site.plan_started_at.should be_present
    site.plan_cycle_started_at.should be_present
    site.plan_cycle_ended_at.should be_present

    go 'my', "/sites/#{site.to_param}/plan/edit"

    page.should have_no_selector "#credit_card"
    page.should have_selector "#credit_card_summary"

    choose "plan_premium_year"

    has_checked_field?("plan_premium_year").should be_true
    click_button "Update plan"

    VCR.use_cassette('ogone/visa_payment_generic') do
      fill_in "Password", with: "123456"
      click_button "Done"
    end

    site.reload.plan.should eql @premium_year

    current_url.should == "http://my.sublimevideo.dev/sites"
    page.should have_content "#{site.plan.title}"

    click_link site.plan.title
    has_checked_field?("plan_premium_year").should be_true
  end

  scenario "failed update" do
    site = create(:site_with_invoice, user: @current_user, plan_id: @free_plan.id)

    go 'my', "/sites/#{site.to_param}/plan/edit"

    VCR.use_cassette('ogone/visa_payment_generic_failed') do
      choose "plan_plus_month"
      click_button "Update plan"
    end

    site.reload

    current_url.should == "http://my.sublimevideo.dev/sites"

    page.should have_content("Embed Code")
    page.should have_content(site.plan.title)
    page.should have_content(I18n.t('site.status.payment_issue'))

    go 'my', "/sites/#{site.to_param}/plan/edit"

    page.should_not have_content(site.plan.title)
    page.should have_content("There has been a transaction error. Please review")
  end

  scenario "cancel next plan automatic update" do
    site = create(:site_with_invoice, user: @current_user, plan_id: @paid_plan.id)

    site.update_attribute(:next_cycle_plan_id, @free_plan.id)

    go 'my', "/sites"

    page.should have_content("#{site.plan.title} plan => #{site.next_cycle_plan.title} plan")

    click_link "#{site.plan.title} plan => #{site.next_cycle_plan.title} plan"

    current_url.should == "http://my.sublimevideo.dev/sites/#{site.token}/plan/edit"

    page.should have_content("Your new #{site.next_cycle_plan.title} plan will automatically start on #{I18n.l(site.plan_cycle_ended_at.tomorrow.midnight, format: :named_date).squeeze(' ')}.")

    click_button "Cancel"

    current_url.should == "http://my.sublimevideo.dev/sites"
    page.should_not have_content("#{site.plan.title} => ")
    page.should have_content(site.plan.title)

    click_link site.plan.title
  end
end

feature "Site in sponsored plan" do
  background do
    sign_in_as :user
  end

  scenario "view" do
    site = create(:site, user: @current_user, last_30_days_main_video_views: 1000, last_30_days_extra_video_views: 500)
    site.sponsor!

    go 'my', "/sites"

    page.should have_content "Sponsored"
    page.should have_content "1,500 plays"

    click_link "Sponsored"

    page.should have_content "Your plan is currently sponsored, if you have any questions, please email #{I18n.t('mailer.sales.email')}."
  end
end

feature "Site in custom plan" do
  background do
    sign_in_as :user
  end

  scenario "add a new site" do
    go 'my', "/sites/new?custom_plan=#{@custom_plan.token}"

    VCR.use_cassette('ogone/visa_payment_generic') do
      choose "plan_custom"
      fill_in "Domain", with: "google.com"
      click_button "Add site"
    end

    current_url.should == "http://my.sublimevideo.dev/sites"
    page.should have_content 'google.com'
    page.should have_content @custom_plan.title
  end

  scenario "view" do
    site = create(:site, user: @current_user, plan_id: @custom_plan.token)

    go 'my', "/sites"

    click_link "Custom"

    current_url.should == "http://my.sublimevideo.dev/sites/#{site.token}/plan/edit"
    page.should have_content @custom_plan.title
  end

  scenario "upgrade site" do
    site = create(:site_with_invoice, user: @current_user, plan_id: @paid_plan.id)

    go 'my', "/sites/#{site.to_param}/plan/edit?custom_plan=#{@custom_plan.token}"

    choose "plan_custom"
    has_checked_field?("plan_custom").should be_true
    click_button "Update plan"

    VCR.use_cassette('ogone/visa_payment_generic') do
      fill_in "Password", with: "123456"
      click_button "Done"
    end

    current_url.should == "http://my.sublimevideo.dev/sites"
    page.should have_content @custom_plan.title
  end
end
