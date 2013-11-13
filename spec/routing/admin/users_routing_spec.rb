require 'spec_helper'

describe Admin::UsersController do

  it { expect(get(with_subdomain('admin', 'users'))).to                        route_to('admin/users#index') }
  it { expect(get(with_subdomain('admin', 'users/1'))).to                      route_to('admin/users#show', id: '1') }
  it { expect(get(with_subdomain('admin', 'users/1/become'))).to               route_to('admin/users#become', id: '1') }
  it { expect(put(with_subdomain('admin', 'users/1'))).to                      route_to('admin/users#update', id: '1') }
  it { expect(get(with_subdomain('admin', 'users/1/new_support_request'))).to  route_to('admin/users#new_support_request', id: '1') }

end
