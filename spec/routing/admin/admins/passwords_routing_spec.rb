require 'spec_helper'

describe Admin::Admins::PasswordsController do

  it { expect(post(with_subdomain('admin', 'password'))).to     route_to('admin/admins/passwords#create') }
  it { expect(put(with_subdomain('admin', 'password'))).to      route_to('admin/admins/passwords#update') }
  it { expect(get(with_subdomain('admin', 'password/new'))).to  route_to('admin/admins/passwords#new') }
  it { expect(get(with_subdomain('admin', 'password/edit'))).to route_to('admin/admins/passwords#edit') }

end
