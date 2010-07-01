require File.dirname(__FILE__) + '/../acceptance_helper'

feature "Video profile navigation:" do
  background do
    sign_in_as_admin
    @video_profile = Factory(:video_profile, :title => "Profile 1")
  end
  
  scenario "navigate through all the video profiles pages" do
    visit "/admin/profiles"
    page.should have_content("Video profiles")
    
    click "New video profile"
    
    current_url.should =~ %r(http://[^/]+/admin/profiles/new)
    page.should have_content("New video profile")
    
    click "cancel"
    
    current_url.should =~ %r(http://[^/]+/admin/profiles)
    
    click "Profile 1"
    
    current_url.should =~ %r(http://[^/]+/admin/profiles/#{@video_profile.id})
    page.should have_content("Video profile #{@video_profile.title}")
    
    click "Back to video profiles"
    
    current_url.should =~ %r(http://[^/]+/admin/profiles)
    
    click "Edit"
    
    current_url.should =~ %r(http://[^/]+/admin/profiles/#{@video_profile.id}/edit)
    page.should have_content("Edit video profile #{@video_profile.title}")
  end
end

feature "New video profile" do
  background do
    sign_in_as_admin
  end
  
  scenario "add a new profile" do
    visit "/admin/profiles"
    
    click "New video profile"
    
    fill_in "Title",          :with => "MP4 HD"
    fill_in "Description",    :with => "A Sublime profile"
    fill_in "Name",           :with => "_hd"
    fill_in "Extname",        :with => "mp4"
    fill_in "Minimum width",  :with => "854"
    fill_in "Minimum height", :with => "480"
    check "Thumbnailable"
    click_button "Create"
    
    current_url.should =~ %r(http://[^/]+/admin/profiles)
    
    page.should have_content('MP4 HD')
    page.should have_content('_hd')
    page.should have_content('mp4')
    page.should have_content('854')
    page.should have_content('480')
    
    profile = VideoProfile.last
    profile.title.should == "MP4 HD"
    profile.description.should == "A Sublime profile"
    profile.name.should == "_hd"
    profile.extname.should == "mp4"
    profile.min_width.should == 854
    profile.min_height.should == 480
    profile.posterframeable.should be_true
  end
end

feature "Video profiles index" do
  background do
    sign_in_as_admin
    @video_profile1 = Factory(:video_profile, :title => "Profile 1")
    @video_profile2 = Factory(:video_profile, :title => "Profile 2")
  end
  
  scenario "list video profiles" do
    visit "/admin/profiles"
    
    page.should have_content("Profile 1")
    page.should have_content("Profile 2")
  end
end

feature "Video profiles show" do
  background do
    sign_in_as_admin
    @video_profile = Factory(:video_profile, :title => "Profile 1")
  end
  
  scenario "list video profiles" do
    visit "/admin/profiles/#{@video_profile.id}"
    
    page.should have_content(@video_profile.title)
    page.should have_content(@video_profile.description)
    page.should have_content(@video_profile.name)
    page.should have_content(@video_profile.extname)
    page.should have_content("Versions")
  end
end

feature "Video profiles edit" do
  background do
    sign_in_as_admin
    @video_profile = Factory(:video_profile, :title => "Profile 1", :name => "_iphone_720p", :extname => "mp4")
  end
  
  scenario "list video profiles" do
    visit "/admin/profiles/#{@video_profile.id}/edit"
    
    page.should have_content("Profile 1")
    page.should have_content(@video_profile.description)
    
    fill_in "Title", :with => "iPhone 1080p"
    click_button "Update"
    
    current_url.should =~ %r(http://[^/]+/admin/profiles)
    
    page.should have_content('iPhone 1080p')
    page.should have_content('_iphone_720p')
    page.should have_content('mp4')
  end
end