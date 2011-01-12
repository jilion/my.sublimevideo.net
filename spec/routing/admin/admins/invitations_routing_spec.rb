require 'spec_helper'

describe Admin::Admins::InvitationsController do

  it { should route(:get,  "/admin/admins/invitation/new").to(:controller => "admin/admins/invitations", :action => :new) }
  it { should route(:post, "/admin/admins/invitation").to(:controller => "admin/admins/invitations", :action => :create) }

end
