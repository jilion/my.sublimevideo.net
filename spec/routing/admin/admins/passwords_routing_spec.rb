require 'spec_helper'

describe Admin::Admins::PasswordsController do

  it { post(with_subdomain('admin', 'password')).should     route_to('admin/admins/passwords#create') }
  it { put(with_subdomain('admin', 'password')).should      route_to('admin/admins/passwords#update') }
  it { get(with_subdomain('admin', 'password/new')).should  route_to('admin/admins/passwords#new') }
  it { get(with_subdomain('admin', 'password/edit')).should route_to('admin/admins/passwords#edit') }

end
