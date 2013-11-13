require 'spec_helper'

describe Admin::Admins::InvitationsController do

  it { expect(get(with_subdomain('admin', 'invitation/new'))).to    route_to('admin/admins/invitations#new') }
  it { expect(post(with_subdomain('admin', 'invitation'))).to       route_to('admin/admins/invitations#create') }
  it { expect(get(with_subdomain('admin', 'invitation/accept'))).to route_to('admin/admins/invitations#edit') }
  it { expect(put(with_subdomain('admin', 'invitation'))).to        route_to('admin/admins/invitations#update') }

end
