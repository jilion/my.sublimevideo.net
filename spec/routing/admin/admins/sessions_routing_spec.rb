require 'spec_helper'

describe Admin::Admins::SessionsController do

  it { expect(get(with_subdomain('admin', 'login'))).to  route_to('admin/admins/sessions#new') }
  it { expect(get(with_subdomain('admin', 'logout'))).to route_to('admin/admins/sessions#destroy') }
  it { expect(post(with_subdomain('admin', 'login'))).to route_to('admin/admins/sessions#create') }

end
