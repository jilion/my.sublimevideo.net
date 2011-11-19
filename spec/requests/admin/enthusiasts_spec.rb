# coding: utf-8
require 'spec_helper'

feature "Enthusiasts actions:" do
  background do
    sign_in_as :admin
    Enthusiast.stub!(:per_page).and_return(2)
    3.times { |i| Factory.create(:enthusiast) }
  end

  scenario "list enthusiasts by clicking on the menu button" do
    click_link 'Enthusiasts'
    current_url.should eq "http://admin.sublimevideo.dev/enthusiasts"
  end

  scenario "should have links to filter enthusiasts" do
    click_link 'Enthusiasts'

    page.should have_content "0 Starred"
    page.should have_content "0 Interested in beta"
    page.should have_content "0 Confirmed & Interested in beta"
    page.should have_content "0 Invited"
    page.should have_content "0 Confirmed"
    page.should have_content "3 Not confirmed"
    page.should have_content "All (3)"

    enthusiast = Enthusiast.first
    enthusiast.touch(:confirmed_at)
    enthusiast.should be_confirmed

    click_link 'Enthusiasts'

    page.should have_content "0 Starred"
    page.should have_content "0 Interested in beta"
    page.should have_content "0 Confirmed & Interested in beta"
    page.should have_content "0 Invited"
    page.should have_content "1 Confirmed"
    page.should have_content "2 Not confirmed"
    page.should have_content "All (3)"

    enthusiast.update_attribute(:interested_in_beta, true)

    click_link 'Enthusiasts'

    page.should have_content "0 Starred"
    page.should have_content "1 Interested in beta"
    page.should have_content "1 Confirmed & Interested in beta"
    page.should have_content "0 Invited"
    page.should have_content "1 Confirmed"
    page.should have_content "2 Not confirmed"
    page.should have_content "All (3)"

    enthusiast.update_attribute(:starred, true)

    click_link 'Enthusiasts'

    page.should have_content "1 Starred"
    page.should have_content "1 Interested in beta"
    page.should have_content "1 Confirmed & Interested in beta"
    page.should have_content "0 Invited"
    page.should have_content "1 Confirmed"
    page.should have_content "2 Not confirmed"
    page.should have_content "All (3)"

    enthusiast.touch(:invited_at)

    click_link 'Enthusiasts'

    page.should have_content "1 Starred"
    page.should have_content "1 Interested in beta"
    page.should have_content "1 Confirmed & Interested in beta"
    page.should have_content "1 Invited"
    page.should have_content "1 Confirmed"
    page.should have_content "2 Not confirmed"
    page.should have_content "All (3)"
  end

  # scenario "should be possible to search" do
  #   Factory.create(:enthusiast, email: "remy@jilion.com")
  #   go 'admin', 'enthusiasts/?page=2'
  # 
  #   page.should have_no_content "remy@jilion.com"
  # 
  #   fill_in "search", with: "remy"
  #   click_button 'search'
  # 
  #   page.should have_content "remy@jilion.com"
  # end

end
