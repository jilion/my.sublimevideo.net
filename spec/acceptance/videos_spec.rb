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

feature "Video transcoded notification from panda as a guest" do
  
  background do
    video = Factory(:video_original, :panda_id => 'd891d9a45c698d587831466f236c6c6c')
  end
  
  scenario "receive notification from panda with a video panda_id" do
    visit "/videos/d891d9a45c698d587831466f236c6c6c/transcoded"
    
    current_url.should =~ %r(http://[^/]+/videos/d891d9a45c698d587831466f236c6c6c/transcoded)
  end
  
end