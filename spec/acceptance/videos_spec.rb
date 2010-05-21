require File.dirname(__FILE__) + '/acceptance_helper'

feature "Videos actions:" do
  
  background do
    sign_in_as_user
  end
  
  scenario "add a new video" do
    visit "/videos"
    attach_file('video_file', "#{Rails.root}/spec/fixtures/railscast_intro.mov")
    click_button "Upload"
    
    current_url.should =~ %r(http://[^/]+/videos)
    page.should have_content('Railscast Intro')
    
    video = @current_user.videos.last
    video.name.should == "Railscast Intro"
  end
  
end