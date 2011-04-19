# coding: utf-8
require 'spec_helper'

feature "Dashboard:" do
  background do
    sign_in_as :admin
  end

  pending "should display the dashboard by default and should include a timeline div" do
    visit "/admin"
    current_url.should =~ %r(http://[^/]+/admin/dashboard)
    
    page.should have_css('#timeline.dashboard_timeline')
  end
end
