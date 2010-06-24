require File.dirname(__FILE__) + '/../acceptance_helper'

feature "Video profile version navigation:" do
  background do
    sign_in_as_admin
    @video_profile = Factory(:video_profile, :title => "Profile 1")
    @video_profile_version = Factory(:video_profile_version, :profile => @video_profile, :width => '123', :height => '321', :command => "Command 1")
    VCR.use_cassette('video_profile_version/pandize') { @video_profile_version.pandize }
    @video_profile.reload
  end
  
  scenario "navigate through all the video profile versions pages" do
    visit "/admin/profiles/#{@video_profile.id}"
    page.should have_content("Video profile #{@video_profile.title}")
    
    click "New version"
    
    current_url.should =~ %r(http://[^/]+/admin/profiles/#{@video_profile.id}/versions/new)
    page.should have_content("New version for video profile #{@video_profile.title}")
    
    click "cancel"
    
    current_url.should =~ %r(http://[^/]+/admin/profiles/#{@video_profile.id})
    
    VCR.use_cassette('video_profile_version/show') { click @video_profile_version.panda_profile_id }
    
    current_url.should =~ %r(http://[^/]+/admin/profiles/#{@video_profile.id}/versions/#{@video_profile_version.id})
    @video_profile.versions.should include @video_profile_version
    page.should have_content("#{@video_profile.title} video profile: #{@video_profile_version.rank.ordinalize} version")
    
    click "Back to #{@video_profile.title}"
    
    current_url.should =~ %r(http://[^/]+/admin/profiles/#{@video_profile.id})
  end
end

feature "New video profile version" do
  background do
    sign_in_as_admin
    @video_profile = Factory(:video_profile, :title => "Profile 1")
  end
  
  scenario "add a new video profile version" do
    visit "/admin/profiles/#{@video_profile.id}"
    
    click "New version"
    
    fill_in "Width",      :with => "123"
    fill_in "Height",     :with => "321"
    fill_in "Command",    :with => "Handbrake CLI"
    VCR.use_cassette('video_profile_version/pandize') { click_button "Create" }
    
    current_url.should =~ %r(http://[^/]+/admin/profiles/#{@video_profile.id})
    
    profile_version = VideoProfileVersion.last
    page.should have_content(profile_version.panda_profile_id)
    page.should have_content(profile_version.id.to_s)
    page.should have_content('experimental')
  end
end

feature "Video profile versions index" do
  background do
    sign_in_as_admin
    @video_profile = Factory(:video_profile, :title => "Profile 1")
    @video_profile_version1 = Factory(:video_profile_version, :profile => @video_profile, :width => '123', :height => '321', :command => "Command 1")
    @video_profile_version2 = Factory(:video_profile_version, :profile => @video_profile, :command => "Command 2")
    VCR.use_cassette('video_profile_version/pandize') do
      @video_profile_version1.pandize
      @video_profile_version2.pandize
    end
  end
  
  scenario "list video profile versions" do
    visit "/admin/profiles/#{@video_profile.id}"
    
    page.should have_content(@video_profile_version1.panda_profile_id)
    page.should have_content(@video_profile_version1.id.to_s)
    page.should have_content(@video_profile_version2.panda_profile_id)
    page.should have_content(@video_profile_version2.id.to_s)
    page.should have_content('experimental')
    page.should_not have_content('active')
  end
  
  scenario "list video profile versions" do
    VCR.use_cassette('video_profile_version/show') { visit "/admin/profiles/#{@video_profile.id}/versions/#{@video_profile_version1.id}" }
    
    page.should have_content(@video_profile_version1.panda_profile_id)
    page.should have_content(@video_profile_version1.state.to_s)
    page.should have_content('Command 1')
    page.should have_content('experimental')
    page.should_not have_content('active')
    page.should have_content(@video_profile_version1.panda_profile_id)
    page.should have_content('123')
    page.should have_content('321')
    page.should have_button('Activate')
  end
end

feature "Video profile versions show" do
  background do
    sign_in_as_admin
    @video_profile = Factory(:video_profile, :title => "Profile 1")
    @video_profile_version1 = Factory(:video_profile_version, :profile => @video_profile, :command => "Command 1")
    @video_profile_version2 = Factory(:video_profile_version, :profile => @video_profile, :command => "Command 2")
    VCR.use_cassette('video_profile_version/pandize') do
      @video_profile_version1.pandize
      @video_profile_version2.pandize
    end
  end
  
  scenario "activate a profile version" do
    VCR.use_cassette('video_profile_version/show') { visit "/admin/profiles/#{@video_profile.id}/versions/#{@video_profile_version1.id}" }
    
    click_button "Activate"
    
    current_url.should =~ %r(http://[^/]+/admin/profiles/#{@video_profile.id})
    
    page.should have_content(@video_profile_version1.panda_profile_id)
    page.should have_content(@video_profile_version1.id.to_s)
    page.should have_content(@video_profile_version2.panda_profile_id)
    page.should have_content(@video_profile_version2.id.to_s)
    page.should have_content('active')
    page.should have_content('deprecated')
    page.should_not have_content('experimental')
    
    VideoProfileVersion.first.should be_active
    VideoProfileVersion.last.should be_deprecated
    
    VCR.use_cassette('video_profile_version/show') { visit "/admin/profiles/#{@video_profile.id}/versions/#{@video_profile_version1.id}" }
    
    page.should have_content('active')
    page.should_not have_content('experimental')
    page.should_not have_button('Activate')
  end
end