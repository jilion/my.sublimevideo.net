require 'spec_helper'

describe Admin::Users::InvitationsController do
  
  it { should route(:get,  "/admin/users/invitation/new").to(:controller => "admin/users/invitations", :action => :new) }
  it { should route(:post, "/admin/users/invitation").to(:controller => "admin/users/invitations", :action => :create) }
  
end