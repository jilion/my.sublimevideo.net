require 'spec_helper'

describe Admin::Admins::InvitationsController do

  it { { get:  '/admin/admins/invitation/new' }.should route_to(controller: 'admin/admins/invitations', action: 'new') }
  it { { post: '/admin/admins/invitation' }.should     route_to(controller: 'admin/admins/invitations', action: 'create') }
  it { { get:  '/admin/invitation/accept' }.should     route_to(controller: 'admin/admins/invitations', action: 'edit') }
  it { { put:  '/admin/invitation' }.should            route_to(controller: 'admin/admins/invitations', action: 'update') }

end
