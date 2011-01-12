require 'spec_helper'

describe Admin::AdminsController do

  it { should route(:get,  "/admin/invitation/accept").to(:controller => "admin/admins/invitations", :action => :edit) }
  it { should route(:put,  "/admin/admins/invitation").to(:controller => "admin/admins/invitations", :action => :update) }
  it { should route(:get,    "/admin/admins").to(:controller => "admin/admins", :action => :index) }
  it { should route(:delete, "/admin/admins/1").to(:controller => "admin/admins", :action => :destroy, :id => '1') }

end
