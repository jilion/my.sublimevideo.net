require 'spec_helper'

describe Admin::Admins::RegistrationsController do

  it { get(with_subdomain('admin', 'account/edit')).should route_to('admin/admins/registrations#edit') }
  it { put(with_subdomain('admin', 'account')).should      route_to('admin/admins/registrations#update') }
  it { delete(with_subdomain('admin', 'account')).should   route_to('admin/admins/registrations#destroy') }

end
