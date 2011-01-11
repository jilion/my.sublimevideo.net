require 'spec_helper'

describe Admin::Admins::PasswordsController do

  it { should route(:post, "/admin/password").to(:controller => "admin/admins/passwords", :action => :create) }
  it { should route(:put,  "/admin/password").to(:controller => "admin/admins/passwords", :action => :update) }
  it { should route(:get,  "/admin/password/new").to(:controller => "admin/admins/passwords", :action => :new) }
  it { should route(:get,  "/admin/password/edit").to(:controller => "admin/admins/passwords", :action => :edit) }

end
