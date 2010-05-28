require File.dirname(__FILE__) + '/acceptance_helper'

feature "Videos actions:" do
  
  background do
    sign_in_as_user
  end
  
  # don't push broken specs
  pending "add a new video" do
    visit "/videos"
    attach_file('video_file', "#{Rails.root}/spec/fixtures/railscast_intro.mov")
    click_button "Upload"
    
    current_url.should =~ %r(http://[^/]+/videos)
    page.should have_content('Railscast Intro')
    
    video = @current_user.videos.last
    video.name.should == "Railscast Intro"
  end
  
end

feature "Video transcoded notification from panda" do
  
  background do
    sign_in_as_user
    @video = Factory(:video_original, :panda_id => 'd891d9a45c698d587831466f236c6c6c', :user => @current_user)
  end
  
  # don't push broken specs
  pending "with a video panda_id" do
    visit "/videos"
    page.should have_content('In progress')
    
    visit "/videos/d891d9a45c698d587831466f236c6c6c/transcoded"
    visit "/videos"
    page.should have_content('Embed code')
    
    @video.reload.should be_active
  end
  
end