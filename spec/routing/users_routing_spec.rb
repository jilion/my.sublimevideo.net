require 'spec_helper'

describe UsersController do
  
  it { should route(:get,    "/invitation/accept").to(:controller => "devise/invitations", :action => :edit) }
  it { should route(:put,    "/invitation/accept").to(:controller => "devise/invitations", :action => :update) }
  
  it { should route(:get,    "/register").to(:controller => "users/registrations", :action => :new) }
  it { should route(:post,   "/register").to(:controller => "users/registrations", :action => :create) }
  
  it { should route(:get,    "/account/edit").to(:controller => "users/registrations", :action => :edit) }
  it { should route(:put,    "/account/credentials").to(:controller => "users/registrations", :action => :update) }
  it { should route(:delete, "/account").to(:controller => "users/registrations", :action => :destroy) }
  
  it { should route(:put,    "/account/info").to(:controller => "users", :action => :update) }
  
  it { should route(:get,    "/login").to(:controller => "devise/sessions", :action => :new) }
  it { should route(:post,   "/login").to(:controller => "devise/sessions", :action => :create) }
  it { should route(:get,    "/logout").to(:controller => "devise/sessions", :action => :destroy) }
  
  it { should route(:get,    "/password/new").to(:controller => "devise/passwords", :action => :new) }
  it { should route(:post,   "/password").to(:controller => "devise/passwords", :action => :create) }
  it { should route(:get,    "/password/edit").to(:controller => "devise/passwords", :action => :edit) }
  it { should route(:put,    "/password").to(:controller => "devise/passwords", :action => :update) }
  
  it { should route(:get,    "/confirmation").to(:controller => "devise/confirmations", :action => :show) }
  it { should route(:get,    "/confirmation/new").to(:controller => "devise/confirmations", :action => :new) }
  it { should route(:post,   "/confirmation").to(:controller => "devise/confirmations", :action => :create) }
  
end