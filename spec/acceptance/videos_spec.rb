require File.dirname(__FILE__) + '/acceptance_helper'

feature "Videos upload:" do
  
  background do
    sign_in_as_user
    VCR.insert_cassette('video_original')
  end
  
  # don't push broken specs
  pending "add a new video" do
    visit "/videos"
    attach_file('video_file', "#{Rails.root}/spec/fixtures/railscast_intro.mov")
    # fill_in "video_panda_id", :with => "f72e511820c12dabc1d15817745225bd"
    click_button "Upload"
    
    current_url.should =~ %r(http://[^/]+/videos)
    page.should have_content('Railscast Intro')
    page.should have_content('In progress')
    
    video = @current_user.videos.last
    video.name.should == "Railscast Intro"
  end
  
  after { VCR.eject_cassette }
  
end

feature "Video transcoded notification from panda" do
  
  background do
    sign_in_as_user
    VCR.insert_cassette('video_original')
    @video = Factory(:video_original, :user => @current_user)
  end
  
  # don't push broken specs
  scenario "with a video panda_id" do
    @current_user.videos.should include @video
    visit "/videos"
    
    page.should have_content('In progress')
    
    @video.formats.each { |f| visit "/videos/#{f.panda_id}/transcoded" }
    visit "/videos"
    
    page.should have_css('tr td.video', :count => 1)
    page.should have_content('Embed code')
    
    Video.last.reload.should be_active
  end
  
  after { VCR.eject_cassette }

end

feature "Videos page:" do
  
  background do
    sign_in_as_user
    VCR.insert_cassette('video_original')
    @video = Factory(:video_original, :user => @current_user)
  end
  
  scenario "sort buttons displayed only if count of videos > 1" do
    @video.formats.each { |f| visit "/videos/#{f.panda_id}/transcoded" }
    visit "/videos"
    
    page.should have_content('Railscast Intro')
    page.should have_css('tr td.video')
    page.should have_no_css('a.sort.name')
    
    Factory(:video_original, :user => @current_user)
    visit "/videos"
    
    page.should have_css('tr td.video', :count => 2)
    page.should have_css('a.sort.date')
    page.should have_css('a.sort.name')
  end
  
  after { VCR.eject_cassette }
  
end
