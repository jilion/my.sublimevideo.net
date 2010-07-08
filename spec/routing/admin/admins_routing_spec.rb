require 'spec_helper'

describe Admin::AdminsController do
  
  it { should route(:get,    "admin/admins/login").to(:controller => "admin/admins/sessions", :action => :new) }
  it { should route(:get,    "admin/admins/logout").to(:controller => "admin/admins/sessions", :action => :destroy) }
  it { should route(:post,   "admin/admins/login").to(:controller => "admin/admins/sessions", :action => :create) }
  # 
  # it { should route(:get,    "admin/login").to(:controller => "devise/sessions", :action => :new) }
  # it { should route(:get,    "admin/logout").to(:controller => "devise/sessions", :action => :destroy) }
  # it { should route(:post,   "admin/login").to(:controller => "devise/sessions", :action => :create) }
  
  it { should route(:post,   "admin/admins/password").to(:controller => "admin/admins/passwords", :action => :create) }
  it { should route(:put,    "admin/admins/password").to(:controller => "admin/admins/passwords", :action => :update) }
  it { should route(:get,    "admin/admins/password/new").to(:controller => "admin/admins/passwords", :action => :new) }
  it { should route(:get,    "admin/admins/password/edit").to(:controller => "admin/admins/passwords", :action => :edit) }
  # 
  # it { should route(:put,    "admin/admins").to(:controller => "admin/registrations", :action => :update) }
  # it { should route(:delete, "admin/admins").to(:controller => "admin/registrations", :action => :destroy) }
  # it { should route(:get,    "admin/admins/edit").to(:controller => "admin/registrations", :action => :edit) }
  
  it { should route(:get,    "users/invitation/new").to(:controller => "admin/admins/invitations", :action => :new) }
  it { should route(:get,    "users/invitation/edit").to(:controller => "admin/admins/invitations", :action => :edit) }
  it { should route(:put,    "users/invitation").to(:controller => "admin/admins/invitations", :action => :update) }
  
  # it { should route(:get,    "admin/admins/unlock").to(:controller => "devise/unlocks", :action => :show) }
  # it { should route(:post,   "admin/admins/unlock").to(:controller => "devise/unlocks", :action => :create) }
  # it { should route(:get,    "admin/admins/unlock/new").to(:controller => "devise/unlocks", :action => :new) }
  
  it { should route(:put,    "admin/admins").to(:controller => "admin/admins/registrations", :action => :update) }
  
  it { should route(:get,    "admin/admins").to(:controller => "admin/admins", :action => :index) }
  it { should route(:delete, "admin/admins/1").to(:controller => "admin/admins", :action => :destroy, :id => '1') }
  
end