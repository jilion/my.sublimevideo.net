require File.dirname(__FILE__) + '/acceptance_helper'

# feature "Videos upload:" do
#   
#   background do
#     sign_in_as :user
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

feature "Video transcoded notification from Panda" do
  
  background do
    sign_in_as :user
    active_video_profile_version = Factory(:video_profile_version)
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
    
    @video.encodings.each { |e| visit "/videos/#{e.video.panda_video_id}/transcoded" }
    Delayed::Job.last.name.should == 'Video#activate'
    VCR.use_cassette('video_encoding/activate') { Delayed::Worker.new(:quiet => true).work_off }
    visit "/videos"
    
    page.should have_css('tr td.video', :count => 1)
    page.should have_content('Embed code')
    
    Video.last.reload.should be_active
  end
  
end

feature "Videos page:" do
  
  background do
    sign_in_as :user
    active_video_profile_version = Factory(:video_profile_version)
    VCR.use_cassette('video_profile_version/pandize') { active_video_profile_version.pandize }
    active_video_profile_version.activate
    
    VCR.use_cassette('video/pandize') do
      @videos = 2.times.inject([]) do |memo, n|
       video = Factory(:video, :user => @current_user)
       video.pandize
       video.update_attribute(:title, "Video #{n+1}")
       memo << video
      end
      Delayed::Worker.new(:quiet => true).work_off
    end
  end
  
  scenario "user without cc" do
    @current_user.cc_type = nil
    @current_user.cc_last_digits = nil
    @current_user.save
    
    visit "/videos"
    
    page.should_not have_content('Video 1')
    page.should_not have_content('Video 2')
    page.should have_content('Add a Credit Card')
  end
  
  scenario "user suspended" do
    @current_user.suspend
    visit "/sites"
    
    current_url.should =~ %r(http://[^/]+/suspended)
  end
  
  scenario "sort buttons displayed only if count of videos > 1" do
    visit "/videos"
    
    page.should have_css('tr td.video', :count => 2)
    page.should have_css('a.sort.date')
    page.should have_css('a.sort.title')
    page.should have_content('Video 1')
    page.should have_content('Video 2')
  end
  
  scenario "video should not appear as active if it's failed" do
    @videos.first.encodings.first.fail
    VCR.use_cassette('video_encoding/activate') { @videos.last.encodings.first.activate }
    visit "/videos"
    
    page.should have_content('Video 1')
    page.should have_content('Video 2')
    page.should have_content('Encoding error')
    page.should have_content('Embed code')
  end
  
  scenario "video should not appear as active if it's suspended" do
    @videos.first.suspend
    VCR.use_cassette('video_encoding/activate') { @videos.last.encodings.first.activate }
    visit "/videos"
    
    page.should have_content('Video 1')
    page.should have_content('Video 2')
    page.should have_content('Suspended')
    page.should have_content('Embed code')
  end
  
  scenario "should not show archived videos" do
    @videos.first.archive
    VCR.use_cassette('video_encoding/activate') { @videos.last.encodings.first.activate }
    visit "/videos"
    
    page.should_not have_content('Video 1')
    page.should have_content('Video 2')
    page.should_not have_content('In progress')
    page.should have_content('Embed code')
  end
  
end