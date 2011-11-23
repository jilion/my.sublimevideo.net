require 'spec_helper'

feature "Plan edit" do
  background do
    sign_in_as :user
    @gold_month = Plan.create(name: "gold", cycle: "month", video_views: 200_000, price: 4990)
    @gold_year = Plan.create(name: "gold", cycle: "year", video_views: 200_000, price: 49900)
  end

  context "site in trial" do
    scenario "view with a free plan without hostname" do
      site = Factory.create(:site, user: @current_user, plan_id: @free_plan.id, hostname: nil)

      go 'my', "/sites/#{site.to_param}/plan/edit"

      current_url.should == "http://my.sublimevideo.dev/sites/#{site.to_param}/plan/edit"
      page.should have_content "add a hostname"
    end

    scenario "update paid plan to free plan" do
      site = Factory.create(:site, user: @current_user, plan_id: @paid_plan.id)

      go 'my', "/sites/#{site.to_param}/plan/edit"

      choose "plan_free"
      has_checked_field?("plan_free").should be_true
      has_unchecked_field?("plan_silver_month").should be_true
      click_button "Update plan"

      site.reload
      site.plan.should eql @free_plan

      current_url.should == "http://my.sublimevideo.dev/sites"
      page.should have_content(site.plan.title)
    end

    scenario "update free plan to paid plan" do
      site = Factory.create(:site, user: @current_user, plan_id: @free_plan.id)

      go 'my', "/sites/#{site.to_param}/plan/edit"

      choose "plan_silver_month"
      click_button "Update plan"

      site.reload
      site.plan.should eq @paid_plan

      current_url.should eq "http://my.sublimevideo.dev/sites"
      page.should have_content(site.plan.title)
    end

    scenario "update free plan to paid plan and skip trial" do
      site = Factory.create(:site, user: @current_user, plan_id: @free_plan.id)

      go 'my', "/sites/#{site.to_param}/plan/edit"

      choose "plan_silver_month"
      check "site_skip_trial"
      VCR.use_cassette('ogone/visa_payment_generic') do
        expect { click_button "Update plan" }.to change(@current_user.invoices, :count)
      end

      site.reload
      site.plan.should eq @paid_plan
      site.invoices.last.should be_paid
      site.plan_id.should eq Plan.find_by_name_and_cycle("silver", "month").id
      site.pending_plan_id.should be_nil
      site.trial_started_at.should be_present
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
  end

  context "site not in trial" do
    scenario "view with a free plan without hostname" do
      site = Factory.create(:site_not_in_trial, user: @current_user, plan_id: @free_plan.id, hostname: nil)

      go 'my', "/sites/#{site.to_param}/plan/edit"

      current_url.should =~ %r(http://[^/]+/sites/#{site.token}/plan/edit$)
      page.should have_content("add a hostname")
    end

    scenario "update paid plan to free plan" do
      site = Factory.create(:site_with_invoice, user: @current_user, plan_id: @paid_plan.id)

      go 'my', "/sites/#{site.to_param}/plan/edit"

      choose "plan_free"
      click_button "Update plan"

      has_checked_field?("plan_free").should be_true
      has_unchecked_field?("plan_silver_month").should be_true

      fill_in "Password", with: "123456"
      click_button "Done"

      site.reload

      current_url.should == "http://my.sublimevideo.dev/sites"
      page.should have_content("#{site.plan.title} => #{site.next_cycle_plan.title}")

      click_link "#{site.plan.title} => #{site.next_cycle_plan.title}"

      page.should have_content("Your new #{site.next_cycle_plan.title} plan will automatically start on #{I18n.l(site.plan_cycle_ended_at.tomorrow.midnight, format: :named_date).squeeze(' ')}.")
    end

    scenario "update free plan to paid plan" do
      site = Factory.create(:site_with_invoice, user: @current_user, plan_id: @gold_month.id)
      site.plan_id = @free_plan.id
      site.save_skip_pwd
      Timecop.travel(2.months.from_now) { site.prepare_pending_attributes; site.apply_pending_attributes }
      site.reload.plan.should eql @free_plan

      go 'my', "/sites/#{site.to_param}/plan/edit"

      VCR.use_cassette('ogone/visa_payment_generic') do
        choose "plan_silver_month"
        click_button "Update plan"
      end

      site.reload.plan.should eql @paid_plan

      current_url.should == "http://my.sublimevideo.dev/sites"
      page.should have_content(site.plan.title)

      click_link site.plan.title
    end

    scenario "update paid plan to paid plan and using registered credit card" do
      site = Factory.create(:site_with_invoice, user: @current_user, plan_id: @gold_month.id)
      site.plan.should eql @gold_month
      site.first_paid_plan_started_at.should be_present
      site.plan_started_at.should be_present
      site.plan_cycle_started_at.should be_present
      site.plan_cycle_ended_at.should be_present

      go 'my', "/sites/#{site.to_param}/plan/edit"

      page.should have_no_selector "#credit_card"
      page.should have_selector "#credit_card_summary"

      choose "plan_gold_year"

      has_checked_field?("plan_gold_year").should be_true
      click_button "Update plan"

      VCR.use_cassette('ogone/visa_payment_generic') do
        fill_in "Password", with: "123456"
        click_button "Done"
      end

      site.reload.plan.should eql @gold_year

      current_url.should == "http://my.sublimevideo.dev/sites"
      page.should have_content "#{site.plan.title}"

      click_link site.plan.title
      has_checked_field?("plan_gold_year").should be_true
    end

    context "When user has no credit card" do
      background do
        sign_in_as :user, without_cc: true, kill_user: true
        @current_user.should_not be_cc
        @site = Factory.create(:site_with_invoice, user: @current_user, plan_id: @gold_month.id)
        @site.plan.should eql @gold_month
        @site.first_paid_plan_started_at.should be_present
        @site.plan_started_at.should be_present
        @site.plan_cycle_started_at.should be_present
        @site.plan_cycle_ended_at.should be_present
      end

      pending "update paid plan to paid plan and using new credit card" do
        go 'my', "/sites/#{@site.to_param}/plan/edit"

        page.should have_selector "#billing_infos"
        # page.should have_no_selector("#credit_card_summary")

        choose "plan_gold_year"
        # set_credit_card(type: 'master')
        has_checked_field?("plan_gold_year").should be_true

        click_button "Update plan"

        VCR.use_cassette('ogone/visa_payment_generic') do
          fill_in "Password", with: "123456"
          click_button "Done"
        end

        @site.reload.plan.should eql @gold_year

        current_url.should == "http://my.sublimevideo.dev/sites"
        page.should have_content(@site.plan.title)

        click_link @site.plan.title
        has_checked_field?("plan_gold_year").should be_true
      end
    end

    scenario "failed update" do
      site = Factory.create(:site_with_invoice, user: @current_user, plan_id: @free_plan.id)

      go 'my', "/sites/#{site.to_param}/plan/edit"

      VCR.use_cassette('ogone/visa_payment_generic_failed') do
        choose "plan_silver_month"
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
      site = Factory.create(:site_with_invoice, user: @current_user, plan_id: @paid_plan.id)

      site.update_attribute(:next_cycle_plan_id, @free_plan.id)

      go 'my', "/sites"

      page.should have_content("#{site.plan.title} => #{site.next_cycle_plan.title}")

      click_link "#{site.plan.title} => #{site.next_cycle_plan.title}"

      current_url.should == "http://my.sublimevideo.dev/sites/#{site.token}/plan/edit"

      page.should have_content("Your new #{site.next_cycle_plan.title} plan will automatically start on #{I18n.l(site.plan_cycle_ended_at.tomorrow.midnight, format: :named_date).squeeze(' ')}.")

      click_button "Cancel"

      current_url.should == "http://my.sublimevideo.dev/sites"
      page.should_not have_content("#{site.plan.title} => ")
      page.should have_content(site.plan.title)

      click_link site.plan.title
    end
  end
end

feature "Site in sponsored plan" do
  background do
    sign_in_as :user
  end

  scenario "view" do
    site = Factory.create(:site, user: @current_user, last_30_days_main_video_views: 1000, last_30_days_extra_video_views: 500)
    site.sponsor!

    go 'my', "/sites"

    page.should have_content "Sponsored"
    page.should have_content "1,500 plays"

    click_link "Sponsored"

    page.should have_content "Your plan is currently sponsored, if you have any questions, please contact us."
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
      click_button "Create"
    end

    current_url.should == "http://my.sublimevideo.dev/sites"
    page.should have_content 'google.com'
    page.should have_content @custom_plan.title
  end

  scenario "view" do
    site = Factory.create(:site, user: @current_user, plan_id: @custom_plan.token)

    go 'my', "/sites"

    click_link "Custom"

    current_url.should == "http://my.sublimevideo.dev/sites/#{site.token}/plan/edit"
    page.should have_content @custom_plan.title
  end

  scenario "upgrade site" do
    site = Factory.create(:site_with_invoice, user: @current_user, plan_id: @paid_plan.id)

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
