require 'spec_helper'

describe Admin::Admins::InvitationsController do

  it { get(with_subdomain('admin', 'invitation/new')).should    route_to('admin/admins/invitations#new') }
  it { post(with_subdomain('admin', 'invitation')).should       route_to('admin/admins/invitations#create') }
  it { get(with_subdomain('admin', 'invitation/accept')).should route_to('admin/admins/invitations#edit') }
  it { put(with_subdomain('admin', 'invitation')).should        route_to('admin/admins/invitations#update') }

end
