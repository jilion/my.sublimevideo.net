require 'spec_helper'

feature "Stats page:" do
  background do
    sign_in_as :admin
  end

  scenario "pagination links displayed only if count of sites > Site.per_page" do
    visit "/admin/stats"
    page.should have_css('div#usage_per_day')
    page.should have_content('Stats')
    page.should have_content('Moving average')
  end
end
