require 'spec_helper'

describe UsersController do
  
  it { should route(:get,    "/register").to(:controller => "devise/registrations", :action => :new) }
  it { should route(:post,   "/register").to(:controller => "devise/registrations", :action => :create) }
  
  it { should route(:get,    "/account/edit").to(:controller => "devise/registrations", :action => :edit) }
  it { should route(:put,    "/account/credentials").to(:controller => "devise/registrations", :action => :update) }
  it { should route(:delete, "/account").to(:controller => "devise/registrations", :action => :destroy) }
  
  it { should route(:put,    "/account/info").to(:controller => "users", :action => :update) }
  
  it { should route(:get,    "/login").to(:controller => "users/sessions", :action => :new) }
  it { should route(:post,   "/login").to(:controller => "users/sessions", :action => :create) }
  it { should route(:get,    "/logout").to(:controller => "users/sessions", :action => :destroy) }
  
  it { should route(:get,    "/confirmation").to(:controller => "devise/confirmations", :action => :show) }
  it { should route(:get,    "/confirmation/new").to(:controller => "devise/confirmations", :action => :new) }
  it { should route(:post,   "/confirmation").to(:controller => "devise/confirmations", :action => :create) }
  
end