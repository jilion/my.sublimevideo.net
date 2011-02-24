require 'spec_helper'

feature "Plans" do
  before(:all) do
    # move this somewhere else and DRY it with the populate
    plans = [
      { name: "dev",        cycle: "month", player_hits: 0,         price: 0 },
      { name: "small",      cycle: "month", player_hits: 3_000,     price: 695 },
      { name: "perso",      cycle: "month", player_hits: 50_000,    price: 1495 },
      { name: "pro",        cycle: "month", player_hits: 200_000,   price: 4995 },
      { name: "enterprise", cycle: "month", player_hits: 1_000_000, price: 9995 },
      { name: "small",      cycle: "year",  player_hits: 3_000,     price: 6900 },
      { name: "perso",      cycle: "year",  player_hits: 50_000,    price: 14900 },
      { name: "pro",        cycle: "year",  player_hits: 200_000,   price: 49900 },
      { name: "enterprise", cycle: "year",  player_hits: 1_000_000, price: 99900 }
    ]
    plans.each { |attributes| Plan.create(attributes) }
  end
  background do
    sign_in_as :user
  end

  # WAITING FOR OCTAVE TO FINISH THE PAGE
  feature "edit" do

    pending "update paid plan to dev plan" do
      site = Factory(:site, user: @current_user)

      visit "/sites/#{site.token}/plan/edit"

      choose "plan_dev"
      click_button "Update plan"

      save_and_open_page

      current_url.should =~ %r(http://[^/]+/sites)
      page.should have_content('Dev')
    end

  end

end
