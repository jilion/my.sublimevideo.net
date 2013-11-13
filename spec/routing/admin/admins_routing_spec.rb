require 'spec_helper'

describe Admin::AdminsController do

  it { expect(get(with_subdomain('admin', 'admins'))).to      route_to('admin/admins#index') }
  it { expect(get(with_subdomain('admin', 'admins/1/edit'))).to      route_to('admin/admins#edit', id: '1') }
  it { expect(patch(with_subdomain('admin', 'admins/1'))).to route_to('admin/admins#update', id: '1') }
  it { expect(patch(with_subdomain('admin', 'admins/1/reset_auth_token'))).to route_to('admin/admins#reset_auth_token', id: '1') }
  it { expect(delete(with_subdomain('admin', 'admins/1'))).to route_to('admin/admins#destroy', id: '1') }

end
