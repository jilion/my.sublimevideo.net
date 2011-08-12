require 'spec_helper'

describe Admin::Admins::SessionsController do

  it { { get:  '/admin/login' }.should  route_to(controller: 'admin/admins/sessions', action: 'new') }
  it { { get:  '/admin/logout' }.should route_to(controller: 'admin/admins/sessions', action: 'destroy') }
  it { { post: '/admin/login' }.should  route_to(controller: 'admin/admins/sessions', action: 'create') }

end
