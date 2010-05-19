require File.dirname(__FILE__) + '/acceptance_helper'

feature "Videos actions:" do
  
  background do
    sign_in_as_user
  end
  
  scenario "add a new video" do
    visit "/videos"
    attach_file('video_file', "#{Rails.root}/spec/watchr/images/failed.png")
    click_button "Upload"
    
    current_url.should =~ %r(http://[^/]+/videos)
    page.should have_content('Failed')
    
    video = @current_user.videos.last
    video.name.should == "Failed"
  end
  
end