require 'spec_helper'

describe Admin::AdminsController do

  it { get(with_subdomain('admin', 'admins')).should      route_to('admin/admins#index') }
  it { get(with_subdomain('admin', 'admins/1/edit')).should      route_to('admin/admins#edit', id: '1') }
  it { patch(with_subdomain('admin', 'admins/1')).should route_to('admin/admins#update', id: '1') }
  it { delete(with_subdomain('admin', 'admins/1')).should route_to('admin/admins#destroy', id: '1') }

end
