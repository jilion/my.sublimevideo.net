require File.dirname(__FILE__) + '/acceptance_helper'

# feature "Videos upload:" do
#   
#   background do
#     sign_in_as_user
#     active_video_profile = Factory(:video_profile)
#     active_video_profile_version = Factory(:video_profile_version, :profile => active_video_profile)
#     VCR.use_cassette('video_profile_version/pandize') { active_video_profile_version.pandize }
#     active_video_profile_version.activate
#     
#     @video = Factory(:video)
#     VCR.use_cassette('video/pandize') { @video.pandize }
#   end
#   
#   pending "add a new video" do
#     visit "/videos"
#     current_url.should =~ %r(http://[^/]+/videos)
#     page.should have_content('Railscast Intro')
#     page.should have_content('In progress')
#     
#     video = @current_user.videos.last
#     video.name.should == "Railscast Intro"
#   end
#   
# end

feature "Video transcoded notification from panda" do
  
  background do
    sign_in_as_user
    active_video_profile = Factory(:video_profile)
    active_video_profile_version = Factory(:video_profile_version, :profile => active_video_profile)
    VCR.use_cassette('video_profile_version/pandize') { active_video_profile_version.pandize }
    active_video_profile_version.activate
    
    @video = Factory(:video, :user => @current_user)
    VCR.use_cassette('video/pandize') do
      @video.pandize
      Delayed::Worker.new(:quiet => true).work_off
    end
  end
  
  scenario "with panda_encoding_id" do
    @current_user.videos.should include @video
    visit "/videos"
    
    page.should have_content('In progress')
    
    @video.encodings.each { |e| visit "/videos/#{e.panda_encoding_id}/transcoded" }
    Delayed::Job.last.name.should == 'VideoEncoding#activate'
    VCR.use_cassette('video_encoding/activate') do
      Delayed::Worker.new(:quiet => true).work_off
    end
    visit "/videos"
    
    page.should have_css('tr td.video', :count => 1)
    page.should have_content('Embed code')
    
    Video.last.reload.should be_active
  end
  
end

feature "Videos page:" do
  
  background do
    sign_in_as_user
    active_video_profile = Factory(:video_profile)
    active_video_profile_version = Factory(:video_profile_version, :profile => active_video_profile)
    VCR.use_cassette('video_profile_version/pandize') { active_video_profile_version.pandize }
    active_video_profile_version.activate
    
    
    VCR.use_cassette('video/pandize') do
       2.times do
         video = Factory(:video, :user => @current_user)
         video.pandize
       end
      Delayed::Worker.new(:quiet => true).work_off
    end
  end
  
  pending "sort buttons displayed only if count of videos > 1" do
    visit "/videos"
    
    page.should have_css('tr td.video', :count => 2)
    page.should have_css('a.sort.date')
    page.should have_css('a.sort.name')
  end
  
end