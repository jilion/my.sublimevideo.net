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

end
