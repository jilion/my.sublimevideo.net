require 'spec_helper'

describe Admin::Admins::SessionsController do
  
  it { should route(:get,  "/admin/login").to(:controller => "admin/admins/sessions", :action => :new) }
  it { should route(:get,  "/admin/logout").to(:controller => "admin/admins/sessions", :action => :destroy) }
  it { should route(:post, "/admin/login").to(:controller => "admin/admins/sessions", :action => :create) }
  
end