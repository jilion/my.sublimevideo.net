require 'spec_helper'

describe Admin::UsersController do

  it { { get: 'admin/users' }.should          route_to(controller: 'admin/users', action: 'index') }
  it { { get: 'admin/users/1' }.should        route_to(controller: 'admin/users', action: 'show', id: '1') }
  it { { get: 'admin/users/1/become' }.should route_to(controller: 'admin/users', action: 'become', id: '1') }

end
