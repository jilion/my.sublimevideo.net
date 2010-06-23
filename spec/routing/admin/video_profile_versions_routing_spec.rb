require 'spec_helper'

describe Admin::VideoProfileVersionsController do
  
  it { should route(:get,  "admin/profiles/1/versions/2").to(:controller => "admin/video_profile_versions", :action => :show, :profile_id => '1', :id => '2') }
  it { should route(:get,  "admin/profiles/1/versions/new").to(:controller => "admin/video_profile_versions", :action => :new, :profile_id => '1') }
  it { should route(:post, "admin/profiles/1/versions").to(:controller => "admin/video_profile_versions", :action => :create, :profile_id => '1') }
  it { should route(:put,  "admin/profiles/1/versions/2").to(:controller => "admin/video_profile_versions", :action => :update, :profile_id => '1', :id => '2') }
  
end