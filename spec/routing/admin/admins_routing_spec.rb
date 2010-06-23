require 'spec_helper'

describe Admin::AdminsController do
  
  # it { should route(:get,    "admin/admins/login").to(:controller => "devise/sessions", :action => :new) }
  # it { should route(:get,    "admin/admins/logout").to(:controller => "devise/sessions", :action => :destroy) }
  # it { should route(:post,   "admin/admins/login").to(:controller => "devise/sessions", :action => :create) }
  # 
  # it { should route(:get,    "admin/login").to(:controller => "devise/sessions", :action => :new) }
  # it { should route(:get,    "admin/logout").to(:controller => "devise/sessions", :action => :destroy) }
  # it { should route(:post,   "admin/login").to(:controller => "devise/sessions", :action => :create) }
  
  # it { should route(:post,   "admin/admins/password").to(:controller => "devise/passwords", :action => :create) }
  # it { should route(:put,    "admin/admins/password").to(:controller => "devise/passwords", :action => :update) }
  # it { should route(:get,    "admin/admins/password/new").to(:controller => "devise/passwords", :action => :new) }
  # it { should route(:get,    "admin/admins/password/edit").to(:controller => "devise/passwords", :action => :edit) }
  # 
  # it { should route(:put,    "admin/admins").to(:controller => "admin/registrations", :action => :update) }
  # it { should route(:delete, "admin/admins").to(:controller => "admin/registrations", :action => :destroy) }
  # it { should route(:get,    "admin/admins/edit").to(:controller => "admin/registrations", :action => :edit) }
  
  it { should route(:get,    "admin/admins/invitation/new").to(:controller => "admin/invitations", :action => :new) }
  it { should route(:get,    "admin/admins/invitation/edit").to(:controller => "admin/invitations", :action => :edit) }
  it { should route(:put,    "admin/admins/invitation").to(:controller => "admin/invitations", :action => :update) }
  
  # it { should route(:get,    "admin/admins/unlock").to(:controller => "devise/unlocks", :action => :show) }
  # it { should route(:post,   "admin/admins/unlock").to(:controller => "devise/unlocks", :action => :create) }
  # it { should route(:get,    "admin/admins/unlock/new").to(:controller => "devise/unlocks", :action => :new) }
  
  it { should route(:put,    "admin/admins").to(:controller => "admin/registrations", :action => :update) }
  
  it { should route(:get,    "admin/admins").to(:controller => "admin/admins", :action => :index) }
  it { should route(:delete, "admin/admins/1").to(:controller => "admin/admins", :action => :destroy, :id => '1') }
  
end