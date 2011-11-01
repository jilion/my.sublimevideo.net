require 'spec_helper'

describe UsersController do

  it { { get:  '/signup' }.should route_to(controller: 'users/registrations', action: 'new') }
  it { { post: '/signup' }.should route_to(controller: 'users/registrations', action: 'create') }

  it { { get:    '/account/edit' }.should        route_to(controller: 'users/registrations', action: 'edit') }
  it { { put:    '/account/credentials' }.should route_to(controller: 'users/registrations', action: 'update') }
  it { { delete: '/account' }.should             route_to(controller: 'users/registrations', action: 'destroy') }

  it { { put: '/account/info' }.should route_to(controller: 'users', action: 'update') }

  it { { get:  '/login' }.should  route_to(controller: 'devise/sessions', action: 'new') }
  it { { post: '/login' }.should  route_to(controller: 'devise/sessions', action: 'create') }
  it { { get:  '/logout' }.should route_to(controller: 'devise/sessions', action: 'destroy') }

  it { { get:  '/confirmation' }.should     route_to(controller: 'devise/confirmations', action: 'show') }
  it { { get:  '/confirmation/new' }.should route_to(controller: 'devise/confirmations', action: 'new') }
  it { { post: '/confirmation' }.should     route_to(controller: 'devise/confirmations', action: 'create') }

  it { { put: '/hide_notice/1' }.should route_to(controller: 'users', action: 'hide_notice', id: '1') }

end
