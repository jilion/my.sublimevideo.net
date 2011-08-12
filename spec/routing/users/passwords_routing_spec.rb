require 'spec_helper'

describe Users::PasswordsController do

  it { { get:  '/password/new' }.should      route_to(controller: 'devise/passwords', action: 'new') }
  it { { post: '/password' }.should          route_to(controller: 'devise/passwords', action: 'create') }
  it { { get:  '/password/edit' }.should     route_to(controller: 'devise/passwords', action: 'edit') }
  it { { put:  '/password' }.should          route_to(controller: 'devise/passwords', action: 'update') }

  it { { post: '/password/validate' }.should route_to(controller: 'users/passwords', action: 'validate') }

end
