require 'spec_helper'

describe Admin::Admins::RegistrationsController do

  it { { get:    '/admin/account/edit' }.should route_to(controller: 'admin/admins/registrations', action: 'edit') }
  it { { put:    '/admin/account' }.should      route_to(controller: 'admin/admins/registrations', action: 'update') }
  it { { delete: '/admin/account' }.should      route_to(controller: 'admin/admins/registrations', action: 'destroy') }

end
