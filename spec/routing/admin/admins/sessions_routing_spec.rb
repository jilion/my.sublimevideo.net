require 'spec_helper'

describe Admin::Admins::SessionsController do

  it { get(with_subdomain('admin', 'login')).should  route_to('admin/admins/sessions#new') }
  it { get(with_subdomain('admin', 'logout')).should route_to('admin/admins/sessions#destroy') }
  it { post(with_subdomain('admin', 'login')).should route_to('admin/admins/sessions#create') }

end
