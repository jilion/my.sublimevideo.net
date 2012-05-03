require 'spec_helper'

describe Admin::UsersController do

  it { get(with_subdomain('admin', 'users')).should               route_to('admin/users#index') }
  it { get(with_subdomain('admin', 'users/1')).should             route_to('admin/users#show', id: '1') }
  it { get(with_subdomain('admin', 'users/1/become')).should      route_to('admin/users#become', id: '1') }
  it { put(with_subdomain('admin', 'users/1')).should             route_to('admin/users#update', id: '1') }
  it { post(with_subdomain('admin', 'users/1/new_ticket')).should route_to('admin/users#new_ticket', id: '1') }

end
