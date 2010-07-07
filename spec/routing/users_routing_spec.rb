require 'spec_helper'

describe UsersController do
  
  it { should route(:get,    "users/login").to(:controller => "devise/sessions", :action => :new) }
  it { should route(:get,    "users/register").to(:controller => "registrations", :action => :new) }
  it { should route(:get,    "users/logout").to(:controller => "devise/sessions", :action => :destroy) }
  it { should route(:post,   "users/login").to(:controller => "devise/sessions", :action => :create) }
  
  it { should route(:post,   "users/password").to(:controller => "devise/passwords", :action => :create) }
  it { should route(:put,    "users/password").to(:controller => "devise/passwords", :action => :update) }
  it { should route(:get,    "users/password/new").to(:controller => "devise/passwords", :action => :new) }
  it { should route(:get,    "users/password/edit").to(:controller => "devise/passwords", :action => :edit) }
  
  it { should route(:post,   "users").to(:controller => "registrations", :action => :create) }
  it { should route(:put,    "users").to(:controller => "registrations", :action => :update) }
  it { should route(:delete, "users").to(:controller => "registrations", :action => :destroy) }
  it { should route(:get,    "users/edit").to(:controller => "registrations", :action => :edit) }
  
  it { should route(:get,    "users/confirmation").to(:controller => "devise/confirmations", :action => :show) }
  it { should route(:post,   "users/confirmation").to(:controller => "devise/confirmations", :action => :create) }
  it { should route(:get,    "users/confirmation/new").to(:controller => "devise/confirmations", :action => :new) }
  
  it { should route(:get,    "users/unlock").to(:controller => "devise/unlocks", :action => :show) }
  it { should route(:post,   "users/unlock").to(:controller => "devise/unlocks", :action => :create) }
  it { should route(:get,    "users/unlock/new").to(:controller => "devise/unlocks", :action => :new) }
  
  it { should route(:put,    "users/1").to(:action => :update, :id => "1") }
  
end