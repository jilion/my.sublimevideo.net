# coding: utf-8
require 'spec_helper'

feature "API /sites" do

  describe "sites" do
    scenario do
      visit '/api/1/sites'

      response.status.should == 401
    end
  end

end
