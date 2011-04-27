require 'spec_helper'

describe Admin::Admins::InvitationsController do

  it { should route(:get,  "/admin/admins/invitation/new").to(:controller => "admin/admins/invitations", :action => :new) }
  it { should route(:post, "/admin/admins/invitation").to(:controller => "admin/admins/invitations", :action => :create) }
  it { should route(:get,  "/admin/invitation/accept").to(:controller => "admin/admins/invitations", :action => :edit) }
  it { should route(:put,  "/admin/invitation").to(:controller => "admin/admins/invitations", :action => :update) }

end
