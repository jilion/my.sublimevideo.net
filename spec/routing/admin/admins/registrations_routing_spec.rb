require 'spec_helper'

describe Admin::Admins::RegistrationsController do

  it { expect(get(with_subdomain('admin', 'account/edit'))).to route_to('admin/admins/registrations#edit') }
  it { expect(put(with_subdomain('admin', 'account'))).to      route_to('admin/admins/registrations#update') }
  it { expect(delete(with_subdomain('admin', 'account'))).to   route_to('admin/admins/registrations#destroy') }

end
