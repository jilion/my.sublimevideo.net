require 'spec_helper'

describe Admin::VideoProfilesController do
  
  it { should route(:get,  "admin/profiles").to(:controller => "admin/video_profiles", :action => :index) }
  it { should route(:get,  "admin/profiles/1").to(:controller => "admin/video_profiles", :action => :show, :id => '1') }
  it { should route(:get,  "admin/profiles/new").to(:controller => "admin/video_profiles", :action => :new) }
  it { should route(:get,  "admin/profiles/1/edit").to(:controller => "admin/video_profiles", :action => :edit, :id => '1') }
  it { should route(:post, "admin/profiles").to(:controller => "admin/video_profiles", :action => :create) }
  it { should route(:put,  "admin/profiles/1").to(:controller => "admin/video_profiles", :action => :update, :id => '1') }
  
end