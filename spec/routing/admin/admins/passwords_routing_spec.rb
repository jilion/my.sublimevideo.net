require 'spec_helper'

describe Admin::Admins::PasswordsController do

  it { { post: '/admin/password' }.should      route_to(controller: 'admin/admins/passwords', action: 'create') }
  it { { put:  '/admin/password' }.should      route_to(controller: 'admin/admins/passwords', action: 'update') }
  it { { get:  '/admin/password/new' }.should  route_to(controller: 'admin/admins/passwords', action: 'new') }
  it { { get:  '/admin/password/edit' }.should route_to(controller: 'admin/admins/passwords', action: 'edit') }

end
