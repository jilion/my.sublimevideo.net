require 'spec_helper'

feature "Delayed Jobs:" do
  background do
    sign_in_as :admin, roles: ['god']
  end

  describe 'update' do
    scenario "sort is kept" do
      expect { Site.delay.monitor_sites_usages }.to change(Delayed::Job, :count).by(1)
      Delayed::Job.first.update_attribute(:locked_at, Time.now)

      go 'admin', 'djs?by_locked_at=desc'

      current_url.should eq "http://admin.sublimevideo.dev/djs?by_locked_at=desc"

      click_button "Unlock"

      current_url.should eq "http://admin.sublimevideo.dev/djs?by_locked_at=desc"
    end
  end

  describe 'delete' do
    scenario "sort is kept" do
      expect { Site.delay.monitor_sites_usages }.to change(Delayed::Job, :count).by(1)
      Delayed::Job.first.update_attribute(:locked_at, Time.now)

      go 'admin', 'djs?by_locked_at=desc'

      current_url.should eq "http://admin.sublimevideo.dev/djs?by_locked_at=desc"

      click_button "Delete"

      current_url.should eq "http://admin.sublimevideo.dev/djs?by_locked_at=desc"
    end
  end

end
