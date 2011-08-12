require 'spec_helper'

describe Admin::AdminsController do

  it { { get:    '/admin/admins' }.should   route_to(controller: 'admin/admins', action: 'index') }
  it { { delete: '/admin/admins/1' }.should route_to(controller: 'admin/admins', action: 'destroy', id: '1') }

end
