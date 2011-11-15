require 'spec_helper'

describe Admin::AdminsController do

  it { get(with_subdomain('admin', 'admins')).should      route_to('admin/admins#index') }
  it { delete(with_subdomain('admin', 'admins/1')).should route_to('admin/admins#destroy', id: '1') }

end
